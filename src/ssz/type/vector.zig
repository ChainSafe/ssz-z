const std = @import("std");
const TypeKind = @import("type_kind.zig").TypeKind;
const isBasicType = @import("type_kind.zig").isBasicType;
const isFixedType = @import("type_kind.zig").isFixedType;
const OffsetIterator = @import("offsets.zig").OffsetIterator;
const merkleize = @import("hashing").merkleize;
const maxChunksToDepth = @import("hashing").maxChunksToDepth;

pub fn FixedVectorType(comptime ST: type, comptime _length: comptime_int) type {
    comptime {
        if (!isFixedType(ST)) {
            @compileError("ST must be fixed type");
        }
        if (_length <= 0) {
            @compileError("length must be greater than 0");
        }
    }
    return struct {
        pub const kind = TypeKind.vector;
        pub const Element: type = ST;
        pub const length: usize = _length;
        pub const Type: type = [length]Element.Type;
        pub const fixed_size: usize = Element.fixed_size * length;
        pub const chunk_count: usize = if (isBasicType(Element)) std.math.divCeil(usize, fixed_size, 32) catch unreachable else length;
        pub const chunk_depth: u8 = maxChunksToDepth(chunk_count);

        pub const default_value: Type = [_]Element.Type{Element.default_value} ** length;

        pub fn hashTreeRoot(value: *const Type, out: *[32]u8) !void {
            var chunks = [_][32]u8{[_]u8{0} ** 32} ** ((chunk_count + 1) / 2 * 2);
            if (comptime isBasicType(Element)) {
                _ = serializeIntoBytes(value, @ptrCast(&chunks));
            } else {
                for (value, 0..) |element, i| {
                    try Element.hashTreeRoot(&element, &chunks[i]);
                }
            }
            try merkleize(@ptrCast(&chunks), chunk_depth, out);
        }

        pub fn serializeIntoBytes(value: *const Type, out: []u8) usize {
            var i: usize = 0;
            for (value) |element| {
                i += Element.serializeIntoBytes(&element, out[i..]);
            }
            return i;
        }

        pub fn deserializeFromBytes(data: []const u8, out: *Type) !void {
            if (data.len != fixed_size) {
                return error.invalidSize;
            }

            for (0..length) |i| {
                try Element.deserializeFromBytes(
                    data[i * Element.fixed_size .. (i + 1) * Element.fixed_size],
                    &out[i],
                );
            }
        }

        pub const serialized = struct {
            pub fn validate(data: []const u8) !void {
                if (data.len != fixed_size) {
                    return error.invalidSize;
                }
                for (0..length) |i| {
                    try Element.serialized.validate(data[i * Element.fixed_size .. (i + 1) * Element.fixed_size]);
                }
            }

            pub fn hashTreeRoot(data: []const u8, out: *[32]u8) !void {
                var chunks = [_][32]u8{[_]u8{0} ** 32} ** ((chunk_count + 1) / 2 * 2);
                if (comptime isBasicType(Element)) {
                    @memcpy(@as([]u8, @ptrCast(&chunks))[0..fixed_size], data);
                } else {
                    for (0..length) |i| {
                        try Element.serialized.hashTreeRoot(
                            data[i * Element.fixed_size .. (i + 1) * Element.fixed_size],
                            &chunks[i],
                        );
                    }
                }
                try merkleize(@ptrCast(&chunks), chunk_depth, out);
            }
        };

        pub fn deserializeFromJson(source: *std.json.Scanner, out: *Type) !void {
            // start array token "["
            switch (try source.next()) {
                .array_begin => {},
                else => return error.InvalidJson,
            }

            for (0..length) |i| {
                try Element.deserializeFromJson(source, &out[i]);
            }

            // end array token "]"
            switch (try source.next()) {
                .array_end => {},
                else => return error.InvalidJson,
            }
        }
    };
}

pub fn VariableVectorType(comptime ST: type, comptime _length: comptime_int) type {
    comptime {
        if (isFixedType(ST)) {
            @compileError("ST must not be fixed type");
        }
        if (_length <= 0) {
            @compileError("length must be greater than 0");
        }
    }
    return struct {
        pub const kind = TypeKind.vector;
        pub const Element: type = ST;
        pub const length: usize = _length;
        pub const Type: type = [length]Element.Type;
        pub const min_size: usize = Element.min_size * length + 4 * length;
        pub const max_size: usize = Element.max_size * length + 4 * length;
        pub const chunk_count: usize = length;
        pub const chunk_depth: u8 = maxChunksToDepth(chunk_count);

        pub const default_value: Type = [_]Element.Type{Element.default_value} ** length;

        pub fn deinit(allocator: std.mem.Allocator, value: *Type) void {
            for (value) |element| {
                Element.deinit(allocator, element);
            }
        }

        pub fn hashTreeRoot(allocator: std.mem.Allocator, value: *const Type, out: *[32]u8) !void {
            var chunks = [_][32]u8{[_]u8{0} ** 32} ** ((chunk_count + 1) / 2 * 2);
            for (value, 0..) |element, i| {
                try Element.hashTreeRoot(allocator, &element, &chunks[i]);
            }
            try merkleize(@ptrCast(&chunks), chunk_depth, out);
        }

        pub fn serializedSize(value: *const Type) usize {
            var size: usize = 0;
            for (value) |*element| {
                size += 4 + Element.serializedSize(element);
            }
            return size;
        }

        pub fn serializeIntoBytes(value: *const Type, out: []u8) usize {
            var variable_index = length * 4;
            for (value, 0..) |element, i| {
                // write offset
                std.mem.writeInt(u32, out[i * 4 ..][0..4], @intCast(variable_index), .little);
                // write element data
                variable_index += Element.serializeIntoBytes(&element, out[variable_index..]);
            }
            return variable_index;
        }

        pub fn deserializeFromBytes(allocator: std.mem.Allocator, data: []const u8, out: *Type) !void {
            if (data.len > max_size or data.len < min_size) {
                return error.InvalidSize;
            }

            const offsets = try readVariableOffsets(data);
            for (0..length) |i| {
                try Element.deserializeFromBytes(allocator, data[offsets[i]..offsets[i + 1]], &out[i]);
            }
        }

        pub fn readVariableOffsets(data: []const u8) ![length + 1]usize {
            var iterator = OffsetIterator(@This()).init(data);
            var offsets: [length + 1]usize = undefined;
            for (0..length) |i| {
                offsets[i] = try iterator.next();
            }
            offsets[length] = data.len;

            return offsets;
        }

        pub const serialized = struct {
            pub fn validate(data: []const u8) !void {
                if (data.len > max_size or data.len < min_size) {
                    return error.InvalidSize;
                }

                const offsets = try readVariableOffsets(data);
                for (0..length) |i| {
                    try Element.serialized.validate(data[offsets[i]..offsets[i + 1]]);
                }
            }

            pub fn hashTreeRoot(allocator: std.mem.Allocator, data: []const u8, out: *[32]u8) !void {
                var chunks = [_][32]u8{[_]u8{0} ** 32} ** ((chunk_count + 1) / 2 * 2);
                const offsets = try readVariableOffsets(data);
                for (0..length) |i| {
                    try Element.serialized.hashTreeRoot(allocator, data[offsets[i]..offsets[i + 1]], &chunks[i]);
                }
                try merkleize(@ptrCast(&chunks), chunk_depth, out);
            }
        };

        pub fn deserializeFromJson(allocator: std.mem.Allocator, source: *std.json.Scanner, out: *Type) !void {
            // start array token "["
            switch (try source.next()) {
                .array_begin => {},
                else => return error.InvalidJson,
            }

            for (0..length) |i| {
                try Element.deserializeFromJson(allocator, source, &out[i]);
            }

            // end array token "]"
            switch (try source.next()) {
                .array_end => {},
                else => return error.InvalidJson,
            }
        }
    };
}

const UintType = @import("uint.zig").UintType;
const BoolType = @import("bool.zig").BoolType;

test "vector - sanity" {
    // create a fixed vector type and instance and round-trip serialize
    const Bytes32 = FixedVectorType(UintType(8), 32);

    var b0: Bytes32.Type = undefined;
    var b0_buf: [Bytes32.fixed_size]u8 = undefined;
    _ = Bytes32.serializeIntoBytes(&b0, &b0_buf);
    try Bytes32.deserializeFromBytes(&b0_buf, &b0);
}
