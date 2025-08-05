const std = @import("std");
const merkleize = @import("hashing").merkleize;
const TypeKind = @import("type_kind.zig").TypeKind;
const BoolType = @import("bool.zig").BoolType;
const hexToBytes = @import("hex").hexToBytes;
const hexLenFromBytes = @import("hex").hexLenFromBytes;
const bytesToHex = @import("hex").bytesToHex;
const maxChunksToDepth = @import("hashing").maxChunksToDepth;
const Node = @import("persistent_merkle_tree").Node;
const computeByteToBitBooleanArray = @import("bit").computeByteToBitBooleanArray;

pub fn BitVector(comptime _length: comptime_int) type {
    const byte_len = std.math.divCeil(usize, _length, 8) catch unreachable;
    return struct {
        data: [byte_len]u8,

        pub const length = _length;

        pub const empty: @This() = .{
            .data = [_]u8{0} ** byte_len,
        };

        pub fn equals(self: *const @This(), other: *const @This()) bool {
            return std.mem.eql(u8, &self.data, &other.data);
        }

        pub fn fromBoolArray(bools: [length]bool) !@This() {
            var bv = empty;
            for (bools, 0..) |bit, i| {
                try bv.set(i, bit);
            }
            return bv;
        }

        pub fn toBoolArray(self: *const @This(), out: *[length]bool) void {
            for (0..length) |i| {
                out[i] = self.get(i) catch unreachable;
            }
        }

        pub fn getTrueBitIndexes(self: *const @This(), allocator: std.mem.Allocator, out: *[]usize) !void {
            var buffer: [length]usize = undefined;
            var true_bit_count: usize = 0;

            for (0..byte_len) |byte_index| {
                const byte = self.data[byte_index];
                const bits = try computeByteToBitBooleanArray(byte);

                for (0..8) |bit_index| {
                    const overall_index = byte_index * 8 + bit_index;
                    if (bits[bit_index]) {
                        buffer[true_bit_count] = overall_index;
                        true_bit_count += 1;
                    }
                }
            }

            out.* = try allocator.alloc(usize, true_bit_count);
            @memcpy(out.*, buffer[0..true_bit_count]);
        }

        pub fn getSingleTrueBit(self: *const @This(), out: *?usize) !void {
            var found_index: ?usize = null;

            for (0..byte_len) |byte_index| {
                const byte = self.data[byte_index];

                if (byte == 0) {
                    continue;
                }

                const bits = try computeByteToBitBooleanArray(byte);

                for (0..8) |bit_index| {
                    const overall_index = byte_index * 8 + bit_index;
                    if (bits[bit_index]) {
                        if (found_index != null) {
                            out.* = null; // more than one true bit found
                            return;
                        } else {
                            found_index = overall_index;
                        }
                    }
                }
            }
            if (found_index == null) {
                out.* = null; // No true bits found
            }
            out.* = found_index;
        }

        pub fn get(self: *const @This(), bit_index: usize) !bool {
            if (bit_index >= length) {
                return error.OutOfRange;
            }

            const byte_idx = bit_index / 8;
            const offset_in_byte: u3 = @intCast(bit_index % 8);
            const mask = @as(u8, 1) << offset_in_byte;
            return (self.data[byte_idx] & mask) == mask;
        }

        /// Set bit value at index `bit_index`
        pub fn set(self: *@This(), bit_index: usize, bit: bool) !void {
            if (bit_index >= length) {
                return error.OutOfRange;
            }

            const byte_index = bit_index / 8;
            const offset_in_byte: u3 = @intCast(bit_index % 8);
            const mask = @as(u8, 1) << offset_in_byte;
            var byte = self.data[byte_index];
            if (bit) {
                // For bit in byte, 1,0 OR 1 = 1
                // byte 100110
                // mask 010000
                // res  110110
                byte |= mask;
                self.data[byte_index] = byte;
            } else {
                // For bit in byte, 1,0 OR 1 = 0
                if ((byte & mask) == mask) {
                    // byte 110110
                    // mask 010000
                    // res  100110
                    byte ^= mask;
                    self.data[byte_index] = byte;
                } else {
                    // Ok, bit is already 0
                }
            }
        }
    };
}

pub fn isBitVectorType(ST: type) bool {
    return ST.kind == .vector and ST.Element.kind == .bool and ST.Type == BitVector(ST.length);
}

pub fn BitVectorType(comptime _length: comptime_int) type {
    comptime {
        if (_length <= 0) {
            @compileError("length must be greater than 0");
        }
    }
    return struct {
        pub const kind = TypeKind.vector;
        pub const Element: type = BoolType();
        pub const length: usize = _length;
        pub const byte_length = std.math.divCeil(usize, length, 8) catch unreachable;
        pub const Type: type = BitVector(length);
        pub const fixed_size: usize = byte_length;
        pub const chunk_count: usize = std.math.divCeil(usize, fixed_size, 32) catch unreachable;
        pub const chunk_depth: u8 = maxChunksToDepth(chunk_count);

        pub const default_value: Type = Type.empty;

        pub fn equals(a: *const Type, b: *const Type) bool {
            return a.equals(b);
        }

        pub fn hashTreeRoot(value: *const Type, out: *[32]u8) !void {
            var chunks = [_][32]u8{[_]u8{0} ** 32} ** ((chunk_count + 1) / 2 * 2);
            _ = serializeIntoBytes(value, @ptrCast(&chunks));
            try merkleize(@ptrCast(&chunks), chunk_depth, out);
        }

        pub fn serializeIntoBytes(value: *const Type, out: []u8) usize {
            @memcpy(out[0..byte_length], &value.data);
            return byte_length;
        }

        pub fn deserializeFromBytes(data: []const u8, out: *Type) !void {
            try serialized.validate(data);

            @memcpy(&out.data, data[0..fixed_size]);
        }

        pub const serialized = struct {
            pub fn validate(data: []const u8) !void {
                if (data.len != fixed_size) {
                    return error.invalidLength;
                }

                // ensure trailing zeros for non-byte-aligned lengths
                if (length % 8 != 0 and @clz(data[fixed_size - 1]) < 8 - length % 8) {
                    return error.trailingData;
                }
            }

            pub fn hashTreeRoot(data: []const u8, out: *[32]u8) !void {
                var chunks = [_][32]u8{[_]u8{0} ** 32} ** ((chunk_count + 1) / 2 * 2);
                @memcpy(@as([]u8, @ptrCast(&chunks))[0..fixed_size], data);
                try merkleize(@ptrCast(&chunks), chunk_depth, out);
            }
        };

        pub const tree = struct {
            pub fn toValue(node: Node.Id, pool: *Node.Pool, out: *Type) !void {
                var nodes: [chunk_count]Node.Id = undefined;

                try node.getNodesAtDepth(pool, chunk_depth, 0, &nodes);

                for (0..chunk_count) |i| {
                    const start_idx = i * 32;
                    const remaining_bytes = byte_length - start_idx;

                    // Determine how many bytes to copy for this chunk
                    const bytes_to_copy = @min(remaining_bytes, 32);

                    // Copy data if there are bytes to copy
                    if (bytes_to_copy > 0) {
                        @memcpy(out.data[start_idx..][0..bytes_to_copy], nodes[i].getRoot(pool)[0..bytes_to_copy]);
                    }
                }
            }

            pub fn fromValue(pool: *Node.Pool, value: *const Type) !Node.Id {
                var nodes: [chunk_count]Node.Id = undefined;
                for (0..chunk_count) |i| {
                    var leaf_buf = [_]u8{0} ** 32;
                    const start_idx = i * 32;
                    const remaining_bytes = byte_length - start_idx;

                    // Determine how many bytes to copy for this chunk
                    const bytes_to_copy = @min(remaining_bytes, 32);

                    // Copy data if there are bytes to copy
                    if (bytes_to_copy > 0) {
                        @memcpy(leaf_buf[0..bytes_to_copy], value.data[start_idx..][0..bytes_to_copy]);
                    }

                    nodes[i] = try pool.createLeaf(&leaf_buf, false);
                }

                return try Node.fillWithContents(pool, &nodes, chunk_depth, false);
            }
        };

        pub fn serializeIntoJson(writer: anytype, in: *const Type) !void {
            const bytes = in.*.data;
            var byte_str: [2 + 2 * byte_length]u8 = undefined;

            _ = try bytesToHex(&byte_str, &bytes);
            try writer.print("\"{s}\"", .{byte_str});
        }

        pub fn deserializeFromJson(source: *std.json.Scanner, out: *Type) !void {
            const hex_bytes = switch (try source.next()) {
                .string => |v| v,
                else => return error.InvalidJson,
            };
            const written = try hexToBytes(&out.data, hex_bytes);
            if (written.len != fixed_size) {
                return error.invalidLength;
            }
            // ensure trailing zeros for non-byte-aligned lengths
            if (length % 8 != 0 and @clz(out.data[fixed_size - 1]) < 8 - length % 8) {
                return error.trailingData;
            }
        }
    };
}

test "BitVectorType - sanity" {
    const length = 44;
    const Bits = BitVectorType(length);
    var b: Bits.Type = Bits.default_value;
    try b.set(0, true);
    try b.set(length - 1, true);

    try std.testing.expectEqual(true, try b.get(0));

    for (1..length - 1) |i| {
        try std.testing.expectEqual(false, try b.get(i));
    }
    try std.testing.expectEqual(true, try b.get(length - 1));

    var b_buf: [Bits.fixed_size]u8 = undefined;
    _ = Bits.serializeIntoBytes(&b, &b_buf);
    try Bits.deserializeFromBytes(&b_buf, &b);
}

test "BitVectorType - sanity with bools" {
    const allocator = std.testing.allocator;
    const Bits = BitVectorType(16);
    const expected_bools = [_]bool{ true, false, true, true, false, true, false, true, true, false, true, true, false, false, true, false };
    const expected_true_bit_indexes = [_]usize{ 0, 2, 3, 5, 7, 8, 10, 11, 14 };
    var b: Bits.Type = try Bits.Type.fromBoolArray(expected_bools);

    var actual_bools: [Bits.length]bool = undefined;
    b.toBoolArray(&actual_bools);

    try std.testing.expectEqualSlices(bool, &expected_bools, &actual_bools);

    var true_bit_indexes: []usize = undefined;
    defer allocator.free(true_bit_indexes);
    try b.getTrueBitIndexes(allocator, &true_bit_indexes);

    try std.testing.expectEqualSlices(usize, &expected_true_bit_indexes, true_bit_indexes);
}
