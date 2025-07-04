const std = @import("std");
const hexToBytes = @import("hex").hexToBytes;
const isFixedType = @import("ssz").isFixedType;

pub const TypeTestCase = struct {
    id: []const u8,
    serializedHex: []const u8,
    json: []const u8,
    rootHex: []const u8,
};

const TypeTestError = error{
    InvalidRootHex,
};

/// ST: ssz type
pub fn typeTest(comptime ST: type) type {
    const TypeTest = struct {
        pub fn run(allocator: std.mem.Allocator, tc: *const TypeTestCase) !void {
            var serializedMax = [_]u8{0} ** 1024;
            const serialized = serializedMax[0..((tc.serializedHex.len - 2) / 2)];
            _ = try hexToBytes(serialized, tc.serializedHex);

            if (comptime isFixedType(ST)) {
                // deserialize
                var value: ST.Type = undefined;
                try ST.deserializeFromBytes(serialized, &value);

                // serialize
                var out = [_]u8{0} ** ST.fixed_size;
                _ = ST.serializeIntoBytes(&value, &out);
                try std.testing.expectEqualSlices(u8, serialized, &out);

                // hash tree root
                // var root = [_]u8{0} ** 32;
                // try ST.hashTreeRoot(&value, root[0..]);
                // const rootHex = try toRootHex(root[0..]);
                // try std.testing.expectEqualSlices(u8, tc.rootHex, rootHex);

                // deserialize from json
                var json_value: ST.Type = undefined;
                var scanner = std.json.Scanner.initCompleteInput(allocator, tc.json);
                defer scanner.deinit();

                try ST.deserializeFromJson(&scanner, &json_value);

                // serialize to json
                var output_json = std.ArrayList(u8).init(allocator);
                defer output_json.deinit();
                var write_stream = std.json.writeStream(output_json.writer(), .{});
                defer write_stream.deinit();
                if (comptime isBasicType(ST)) {
                    try ST.serializeIntoJson(&write_stream, &json_value);
                } else {
                    try ST.serializeIntoJson(allocator, &write_stream, &json_value);
                }

            } else {
                // deserialize
                var value = ST.default_value;
                defer ST.deinit(allocator, &value);

                try ST.deserializeFromBytes(allocator, serialized, &value);

                // serialize
                const out = try allocator.alloc(u8, ST.serializedSize(&value));
                defer allocator.free(out);

                _ = ST.serializeIntoBytes(&value, out);
                try std.testing.expectEqualSlices(u8, serialized, out);

                // hash tree root
                // var root = [_]u8{0} ** 32;
                // try ST.hashTreeRoot(&value, root[0..]);
                // const rootHex = try toRootHex(root[0..]);
                // try std.testing.expectEqualSlices(u8, tc.rootHex, rootHex);

                // deserialize from json
                var json_value = ST.default_value;
                defer ST.deinit(allocator, &json_value);

                var scanner = std.json.Scanner.initCompleteInput(allocator, tc.json);
                defer scanner.deinit();

                try ST.deserializeFromJson(allocator, &scanner, &json_value);

                // serialize to json
                var output_json = std.ArrayList(u8).init(allocator);
                defer output_json.deinit();
                var write_stream = std.json.writeStream(output_json.writer(), .{});
                defer write_stream.deinit();
                if (comptime isBasicType(ST)) {
                    try ST.serializeIntoJson(&write_stream, &json_value);
                } else {
                    try ST.serializeIntoJson(allocator, &write_stream, &json_value);
                }

                try std.testing.expectEqualSlices(u8, tc.json, output_json.items);
            }
        }
    };
    return TypeTest;
}
