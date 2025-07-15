const std = @import("std");
const yaml = @import("yaml");
const spec_test_options = @import("spec_test_options");
const types = @import("generic_types.zig");
const snappy = @import("snappy");
const hex = @import("hex");
const ssz = @import("ssz");
const Node = @import("persistent_merkle_tree").Node;

const Allocator = std.mem.Allocator;

pub fn parseYaml(comptime ST: type, allocator: Allocator, y: yaml.Yaml, out: *ST.Type) !void {
    if (comptime ssz.isBitVectorType(ST)) {
        const bytes_buf = try allocator.alloc(u8, ST.byte_length + 2);
        const yaml_bytes = try y.parse(allocator, []const u8);
        const bytes = try hex.hexToBytes(bytes_buf, yaml_bytes);
        out.* = ST.Type{ .data = bytes[0..ST.byte_length].* };
        return;
    } else if (comptime ssz.isBitListType(ST)) {
        const bytes_buf = try allocator.alloc(u8, ((ST.limit + 7) / 8) + 2);
        const yaml_bytes = try y.parse(allocator, []const u8);
        const data = try hex.hexToBytes(bytes_buf, yaml_bytes);
        // we need to find the padding bit to find the bit_len, and then remove it
        // do this manually, otherwise we're testing the deserialization codepath against itself
        const last_byte = data[data.len - 1];

        const last_byte_clz = @clz(last_byte);
        const last_1_index: u3 = @intCast(7 - last_byte_clz);
        const bit_len = (data.len - 1) * 8 + last_1_index;
        data[data.len - 1] ^= @as(u8, 1) << last_1_index;

        var bl = ST.default_value;
        try bl.resize(allocator, bit_len);
        if (bit_len > 0) {
            if (bit_len % 8 == 0) {
                @memcpy(bl.data.items[0 .. data.len - 1], data[0 .. data.len - 1]);
            } else {
                @memcpy(bl.data.items[0..data.len], data);
            }
        }

        out.* = bl;
        return;
    } else if (ST.kind == .container) {
        const map = try y.docs.items[0].asMap();
        inline for (ST.fields) |field| {
            y.docs.items[0] = map.get(field.name).?;
            try parseYaml(field.type, allocator, y, &@field(out, field.name));
        }
        return;
    } else if (ST.kind == .list) {
        if (comptime ssz.isByteListType(ST)) {
            const hex_bytes = try y.parse(allocator, []u8);
            const bytes_buf = try allocator.alloc(u8, (hex_bytes.len - 2) / 2);
            const bytes = try hex.hexToBytes(bytes_buf, hex_bytes);
            out.* = ST.Type.empty;
            try out.resize(allocator, bytes.len);
            @memcpy(out.items, bytes);
            return;
        } else if (comptime ssz.isBasicType(ST.Element)) {
            const items = try y.parse(allocator, []ST.Element.Type);
            out.* = ST.Type.empty;
            try out.resize(allocator, items.len);
            @memcpy(out.items, items);
            return;
        } else {
            const list = try y.docs.items[0].asList();
            var l = ST.Type.empty;
            try l.resize(allocator, list.len);
            for (list, 0..) |v, i| {
                y.docs.items[0] = v;
                try parseYaml(ST.Element, allocator, y, &l.items[i]);
            }
            out.* = l;
            return;
        }
    } else if (ST.kind == .vector) {
        if (comptime ssz.isByteVectorType(ST)) {
            const hex_bytes = try y.parse(allocator, []u8);
            const bytes_buf = try allocator.alloc(u8, (hex_bytes.len - 2) / 2);
            const bytes = try hex.hexToBytes(bytes_buf, hex_bytes);
            out.* = bytes[0..ST.fixed_size].*;
            return;
        } else if (comptime ssz.isBasicType(ST.Element)) {
            out.* = try y.parse(allocator, ST.Type);
            return;
        } else {
            const list = try y.docs.items[0].asList();
            for (list, 0..) |v, i| {
                y.docs.items[0] = v;
                try parseYaml(ST.Element, allocator, y, &out[i]);
            }
            return;
        }
    } else {
        out.* = try y.parse(allocator, ST.Type);
        return;
    }
}

pub fn parseYamlToJson(allocator: Allocator, y: yaml.Yaml.Value, writer: anytype) !void {
    switch (y) {
        .empty => return,
        .scalar => |scalar| {
            const isBool = std.mem.eql(u8, scalar, "true") or std.mem.eql(u8, scalar, "false");

            return if (isBool)
                try writer.print("{s}", .{scalar})
            else
                try writer.print("\"{s}\"", .{scalar});
        },
        .list => |list| {
            try writer.beginArray();
            for (list) |elem| {
                try parseYamlToJson(allocator, elem, writer);
            }
            try writer.endArray();
        },
        .map => |map| {
            try writer.beginObject();
            for (map.keys(), map.values()) |key, value| {
                try writer.objectField(key);
                try parseYamlToJson(allocator, value, writer);
            }
            try writer.endObject();
        },
    }
}

pub fn validTestCase(comptime ST: type, gpa: Allocator, path: std.fs.Dir, meta_file_name: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    // read expected root

    const meta_file = try path.openFile(meta_file_name, .{});
    defer meta_file.close();
    const Meta = struct {
        root: []const u8,
    };
    const meta_bytes = try meta_file.readToEndAlloc(allocator, 1_000);

    var meta_yaml = yaml.Yaml{ .source = meta_bytes };
    try meta_yaml.load(allocator);
    const meta = try meta_yaml.parse(allocator, Meta);

    const root_expected = try hex.hexToRoot(meta.root[0..66]);

    // read yaml

    const value_file = try path.openFile("value.yaml", .{});
    defer value_file.close();
    const value_bytes = try value_file.readToEndAlloc(allocator, 100_000_000);

    var value_yaml = yaml.Yaml{ .source = value_bytes };
    value_yaml.load(allocator) catch |e| {
        value_yaml.parse_errors.renderToStdErr(.{ .ttyconf = .no_color });
        return e;
    };

    // read expected json

    var expected_json = std.ArrayList(u8).init(allocator);
    defer expected_json.deinit();
    var write_stream = std.json.writeStream(expected_json.writer(), .{});
    defer write_stream.deinit();

    try parseYamlToJson(allocator, value_yaml.docs.items[0], &write_stream);

    // std.debug.print("{s}\n", .{@as([]const u8, expected_json.items)});

    // read expected value

    var value_expected = try allocator.create(ST.Type);
    value_expected.* = ST.default_value;
    try parseYaml(ST, allocator, value_yaml, value_expected);

    // read expected serialized

    const serialized_file = try path.openFile("serialized.ssz_snappy", .{});
    defer serialized_file.close();
    const serialized_snappy_bytes = try serialized_file.readToEndAlloc(allocator, 100_000_000);

    const serialized_buf = try allocator.alloc(u8, try snappy.uncompressedLength(serialized_snappy_bytes));
    const serialized_len = try snappy.uncompress(serialized_snappy_bytes, serialized_buf);
    const serialized_expected = serialized_buf[0..serialized_len];

    // test serialization - value to ssz

    {
        const serialized_actual = try allocator.alloc(
            u8,
            if (comptime ssz.isFixedType(ST)) ST.fixed_size else ST.serializedSize(value_expected),
        );
        const serialized_actual_size = ST.serializeIntoBytes(value_expected, serialized_actual);
        try std.testing.expectEqual(serialized_expected.len, serialized_actual_size);
        try std.testing.expectEqualSlices(u8, serialized_expected, serialized_actual);
    }

    // test deserialization - ssz to value

    {
        try ST.serialized.validate(serialized_expected);

        var value_actual = try allocator.create(ST.Type);
        value_actual.* = ST.default_value;

        if (comptime ssz.isFixedType(ST)) {
            try ST.deserializeFromBytes(serialized_expected, value_actual);
        } else {
            try ST.deserializeFromBytes(allocator, serialized_expected, value_actual);
        }
        try std.testing.expectEqualDeep(&value_expected, &value_actual);
    }

    // test serialization - value to json

    {
        var serialized_actual = std.ArrayList(u8).init(allocator);
        defer serialized_actual.deinit();
        var write_stream_actual = std.json.writeStream(serialized_actual.writer(), .{});
        defer write_stream_actual.deinit();

        if (comptime ssz.isBasicType(ST)) {
            try ST.serializeIntoJson(&write_stream_actual, value_expected);
        } else {
            try ST.serializeIntoJson(allocator, &write_stream_actual, value_expected);
        }

        try std.testing.expectEqualSlices(u8, expected_json.items, serialized_actual.items);
    }

    // test deserialization - json to value
    {
        var value_actual = try allocator.create(ST.Type);
        value_actual.* = ST.default_value;

        var scanner = std.json.Scanner.initCompleteInput(allocator, expected_json.items);
        defer scanner.deinit();

        if (comptime ssz.isFixedType(ST)) {
            try ST.deserializeFromJson(&scanner, value_actual);
        } else {
            try ST.deserializeFromJson(allocator, &scanner, value_actual);
        }

        try std.testing.expectEqualDeep(&value_expected, &value_actual);
    }

    // test merkleization

    var root_actual_oneshot: [32]u8 = undefined;
    if (comptime ssz.isFixedType(ST)) {
        try ST.hashTreeRoot(value_expected, &root_actual_oneshot);
    } else {
        try ST.hashTreeRoot(allocator, value_expected, &root_actual_oneshot);
    }
    try std.testing.expectEqualSlices(u8, &root_expected, &root_actual_oneshot);

    var root_actual_serialized: [32]u8 = undefined;
    if (comptime ssz.isFixedType(ST)) {
        try ST.serialized.hashTreeRoot(serialized_expected, &root_actual_serialized);
    } else {
        try ST.serialized.hashTreeRoot(allocator, serialized_expected, &root_actual_serialized);
    }
    try std.testing.expectEqualSlices(u8, &root_expected, &root_actual_serialized);

    const Hasher = ssz.Hasher(ST);
    var hash_scratch: ssz.HasherData = if (comptime ssz.isBasicType(ST)) undefined else try Hasher.init(allocator);
    var root_actual: [32]u8 = undefined;
    try Hasher.hash(&hash_scratch, value_expected, &root_actual);
    try std.testing.expectEqualSlices(u8, &root_expected, &root_actual);

    // test conversion between tree and value

    var pool = try Node.Pool.init(gpa, 1_000_000);
    defer pool.deinit();

    const node = if (comptime ssz.isFixedType(ST))
        try ST.tree.fromValue(&pool, value_expected)
    else
        try ST.tree.fromValue(allocator, &pool, value_expected);

    try std.testing.expectEqualSlices(u8, &root_expected, node.getRoot(&pool));

    const value_from_tree = try allocator.create(ST.Type);
    value_from_tree.* = ST.default_value;

    if (comptime ssz.isFixedType(ST)) {
        try ST.tree.toValue(node, &pool, value_from_tree);
    } else {
        try ST.tree.toValue(allocator, node, &pool, value_from_tree);
    }
    try std.testing.expectEqualDeep(value_expected, value_from_tree);
}

pub fn invalidTestCase(comptime ST: type, gpa: Allocator, path: std.fs.Dir) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    // read expected serialized

    const serialized_file = try path.openFile("serialized.ssz_snappy", .{});
    defer serialized_file.close();
    const serialized_snappy_bytes = try serialized_file.readToEndAlloc(allocator, 1_000_000);

    const serialized_buf = try allocator.alloc(u8, try snappy.uncompressedLength(serialized_snappy_bytes));
    const serialized_len = try snappy.uncompress(serialized_snappy_bytes, serialized_buf);
    const serialized_expected = serialized_buf[0..serialized_len];

    // test deserialization

    try std.testing.expectError(error.InvalidSSZ, validate(ST, serialized_expected));

    var value_actual = ST.default_value;

    try std.testing.expectError(error.InvalidSSZ, deserialize(ST, allocator, serialized_expected, &value_actual));
}

// Wrap validate with a single error type
fn validate(comptime ST: type, serialized: []const u8) !void {
    return ST.serialized.validate(serialized) catch error.InvalidSSZ;
}

// Wrap deserializeFromBytes with a single error type
fn deserialize(comptime ST: type, allocator: Allocator, serialized_expected: []const u8, value_actual: anytype) !void {
    if (comptime ssz.isFixedType(ST)) {
        return ST.deserializeFromBytes(serialized_expected, value_actual) catch error.InvalidSSZ;
    } else {
        return ST.deserializeFromBytes(allocator, serialized_expected, value_actual) catch error.InvalidSSZ;
    }
}
