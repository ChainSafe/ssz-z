const std = @import("std");
const TypeKind = @import("type_kind.zig").TypeKind;
const isBasicType = @import("type_kind.zig").isBasicType;
const isFixedType = @import("type_kind.zig").isFixedType;

const hashing = @import("hashing");
const mixInLength = hashing.mixInLength;

const progressive = @import("progressive.zig");

pub fn ProgressiveListType(comptime Element: type, comptime limit: comptime_int) type {
    comptime {
        if (limit <= 0) @compileError("limit must be > 0");
    }
    return struct {
        pub const kind = TypeKind.progressive_list;

        // In-memory representation
        pub const Type = std.ArrayListUnmanaged(Element.Type);

        pub const default_value: Type = Type.empty;

        pub fn deinit(a: std.mem.Allocator, v: *Type) void {
            if (!comptime isBasicType(Element)) {
                for (v.items) |*e| Element.deinit(a, e);
            }
            v.deinit(a);
        }

        pub fn equals(a: *const Type, b: *const Type) bool {
            if (a.items.len != b.items.len) return false;
            for (a.items, b.items) |ae, be| {
                if (!Element.equals(&ae, &be)) return false;
            }
            return true;
        }

        pub fn serializedSize(v: *const Type) usize {
            if (comptime isFixedType(Element)) {
                return v.items.len * Element.fixed_size;
            } else {
                var size: usize = v.items.len * 4;
                for (v.items) |e| size += Element.serializedSize(&e);
                return size;
            }
        }

        pub fn serializeIntoBytes(v: *const Type, out: []u8) usize {
            if (comptime isFixedType(Element)) {
                var w: usize = 0;
                for (v.items) |e| w += Element.serializeIntoBytes(&e, out[w..]);
                return w;
            } else {
                var var_idx: usize = v.items.len * 4;
                for (v.items, 0..) |e, i| {
                    std.mem.writeInt(u32, out[i * 4 ..][0..4], @intCast(var_idx), .little);
                    var_idx += Element.serializeIntoBytes(&e, out[var_idx..]);
                }
                return var_idx;
            }
        }

        pub fn serializeIntoJson(allocator: std.mem.Allocator, writer: anytype, in: *const Type) !void {
            _ = allocator;
            try writer.beginArray();
            for (in.items) |e| {
                try Element.serializeIntoJson(writer, &e);
            }
            try writer.endArray();
        }

        pub fn deserializeFromJson(allocator: std.mem.Allocator, source: *std.json.Scanner, out: *Type) !void {
            switch (try source.next()) {
                .array_begin => {},
                else => return error.InvalidJson,
            }

            var i: usize = 0;
            while (i <= limit) : (i += 1) {
                switch (try source.peekNextTokenType()) {
                    .array_end => {
                        _ = try source.next();
                        return;
                    },
                    else => {},
                }

                _ = try out.addOne(allocator);
                out.items[i] = Element.default_value;
                try Element.deserializeFromJson(source, &out.items[i]);
            }
            return error.invalidLength;
        }

        pub fn deserializeFromBytes(
            allocator: std.mem.Allocator,
            data: []const u8,
            out: *Type,
        ) !void {
            if (comptime isFixedType(Element)) {
                if (data.len % Element.fixed_size != 0) return error.InvalidSize;
                const n = data.len / Element.fixed_size;
                if (n > limit) return error.gtLimit;

                try out.resize(allocator, n);
                @memset(out.items[0..n], Element.default_value);

                var i: usize = 0;
                while (i < n) : (i += 1) {
                    try Element.deserializeFromBytes(
                        data[i * Element.fixed_size .. (i + 1) * Element.fixed_size],
                        &out.items[i],
                    );
                }
            } else {
                const VL = @import("list.zig").VariableListType(Element, limit);
                const offs = try VL.readVariableOffsets(allocator, data);
                defer allocator.free(offs);

                const n = offs.len - 1;
                if (n > limit) return error.gtLimit;

                try out.resize(allocator, n);
                @memset(out.items[0..n], Element.default_value);

                var i: usize = 0;
                while (i < n) : (i += 1) {
                    try Element.deserializeFromBytes(
                        allocator,
                        data[offs[i]..offs[i + 1]],
                        &out.items[i],
                    );
                }
            }
        }

        /// Value path hashing delegates to the serialized path for consistency
        pub fn hashTreeRoot(a: std.mem.Allocator, v: *const Type, out: *[32]u8) !void {
            const total = serializedSize(v);
            const buf = try a.alloc(u8, total);
            defer a.free(buf);
            _ = serializeIntoBytes(v, buf);
            try serialized.hashTreeRoot(a, buf, out);
        }

        pub const serialized = struct {
            pub fn validate(data: []const u8) !void {
                if (comptime isFixedType(Element)) {
                    if (data.len % Element.fixed_size != 0) return error.InvalidSize;
                } else {
                    // Rely on VariableListType iterator validation for offsets
                    const VL = @import("list.zig").VariableListType(Element, limit);
                    const it = @import("offsets.zig").OffsetIterator(VL).init(data);
                    _ = try it.firstOffset();
                }
            }

            pub fn length(data: []const u8) !usize {
                if (comptime isFixedType(Element)) {
                    if (data.len % Element.fixed_size != 0) return error.InvalidSize;
                    return data.len / Element.fixed_size;
                } else {
                    if (data.len == 0) return 0;
                    const VL = @import("list.zig").VariableListType(Element, limit);
                    var it = @import("serialized.zig").OffsetIterator(VL).init(data);
                    return try it.firstOffset() / 4;
                }
            }

            pub fn hashTreeRoot(a: std.mem.Allocator, data: []const u8, out: *[32]u8) !void {
                const len = try length(data);
                if (len == 0) {
                    @memset(out, 0);
                    mixInLength(0, out);
                    return;
                }

                const leaf_count: usize = if (comptime isBasicType(Element))
                    (data.len + 31) / 32
                else
                    len;

                var offs_opt: ?[]usize = null;
                defer if (offs_opt) |o| a.free(o);
                if (comptime (!isBasicType(Element) and !isFixedType(Element))) {
                    const VL = @import("list.zig").VariableListType(Element, limit);
                    offs_opt = try VL.readVariableOffsets(a, data);
                }

                const Ctx = struct { allocator: std.mem.Allocator, data: []const u8, offs: ?[]usize };
                var ctx = Ctx{ .allocator = a, .data = data, .offs = offs_opt };

                const getLeaf = struct {
                    fn f(pctx: ?*anyopaque, index: usize, leaf_out: *[32]u8) !void {
                        const c: *Ctx = @ptrCast(@alignCast(pctx.?));
                        if (comptime isBasicType(Element)) {
                            const start = index * 32;
                            const end = @min(start + 32, c.data.len);
                            @memset(leaf_out, 0);
                            if (start < end) @memcpy(leaf_out[0 .. end - start], c.data[start..end]);
                            return;
                        }
                        if (comptime isFixedType(Element)) {
                            const sz = Element.fixed_size;
                            const off = index * sz;
                            var tmp: [32]u8 = undefined;
                            try Element.serialized.hashTreeRoot(c.allocator, c.data[off .. off + sz], &tmp);
                            @memcpy(leaf_out, &tmp);
                            return;
                        }
                        const offs = c.offs.?;
                        var tmp: [32]u8 = undefined;
                        try Element.serialized.hashTreeRoot(c.allocator, c.data[offs[index]..offs[index + 1]], &tmp);
                        @memcpy(leaf_out, &tmp);
                    }
                }.f;

                try progressive.merkleizeByLeafFn(a, leaf_count, getLeaf, &ctx, out);
                mixInLength(len, out);
            }
        };
    };
}

// Convenience wrappers
pub fn ProgressiveByteListType(comptime limit: comptime_int) type {
    const U8 = @import("uint.zig").UintType(8);
    return ProgressiveListType(U8, limit);
}

// Progressive bitlist packs bits plus a termination bit and mixes in bit length
pub fn ProgressiveBitListType(comptime limit: comptime_int) type {
    return struct {
        pub const kind = TypeKind.progressive_list;
        pub const Type = struct {
            data: std.ArrayListUnmanaged(u8),
            bit_len: usize,

            pub fn deinit(self: *Type, a: std.mem.Allocator) void {
                self.data.deinit(a);
            }
        };

        pub const default_value: Type = .{ .data = .{}, .bit_len = 0 };

        pub fn deinit(a: std.mem.Allocator, v: *Type) void {
            v.data.deinit(a);
        }
        pub fn equals(a: *const Type, b: *const Type) bool {
            return a.bit_len == b.bit_len and std.mem.eql(u8, a.data.items, b.data.items);
        }

        fn encBytes(bit_len: usize) usize {
            return (bit_len + 1 + 7) / 8;
        }

        pub fn hashTreeRoot(a: std.mem.Allocator, v: *const Type, out: *[32]u8) !void {
            const n = encBytes(v.bit_len);
            const chunk_len = ((n + 31) / 32 + 1) / 2 * 2;
            const chunks = try a.alloc([32]u8, chunk_len);
            defer a.free(chunks);
            const zero = [_]u8{0} ** 32;
            @memset(chunks, zero);

            const bytes: []u8 = @as([]u8, @ptrCast(chunks));
            @memcpy(bytes[0..v.data.items.len], v.data.items);

            const ti = v.bit_len;
            const bi = ti % 8;
            const by = ti / 8;
            const chunk_index = by / 32;
            const byte_within = by % 32;
            chunks[chunk_index][byte_within] |= @as(u8, 1) << @intCast(bi);

            try progressive.merkleizeChunks(a, chunks, out);
            mixInLength(v.bit_len, out);
        }

        pub const serialized = struct {
            pub fn validate(data: []const u8) !void {
                if (data.len == 0) return error.InvalidSize;
                var any_set = false;
                inline for (0..8) |i| {
                    if (((data[data.len - 1] >> @intCast(i)) & 1) == 1) {
                        any_set = true;
                    }
                }
                if (!any_set) return error.MissingTerminationBit;
            }
            pub fn length(data: []const u8) !usize {
                if (data.len == 0) return error.InvalidSize;
                var pos: u3 = 0;
                inline for (0..8) |i| {
                    if (((data[data.len - 1] >> @intCast(i)) & 1) == 1) {
                        pos = @intCast(i);
                    }
                }
                return (data.len - 1) * 8 + pos;
            }
            pub fn hashTreeRoot(a: std.mem.Allocator, data: []const u8, out: *[32]u8) !void {
                const bit_len = try length(data);
                const n = encBytes(bit_len);
                const chunk_len = ((n + 31) / 32 + 1) / 2 * 2;
                const chunks = try a.alloc([32]u8, chunk_len);
                defer a.free(chunks);
                const zero = [_]u8{0} ** 32;
                @memset(chunks, zero);

                const bytes: []u8 = @as([]u8, @ptrCast(chunks));
                @memcpy(bytes[0..n], data[0..n]);
                // Set termination bit in the packed bytes copy to ensure correct root
                const ti = bit_len;
                const bi = ti % 8;
                const by = ti / 8;
                const chunk_index = by / 32;
                const byte_within = by % 32;
                chunks[chunk_index][byte_within] |= @as(u8, 1) << @intCast(bi);

                try progressive.merkleizeChunks(a, chunks, out);
                mixInLength(bit_len, out);
            }
        };

        // Keep the limit in the type to avoid unused parameter warning
        pub const limit_value: usize = limit;
    };
}
