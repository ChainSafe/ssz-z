const std = @import("std");

const isBasicType = @import("type/type_kind.zig").isBasicType;
const isBitListType = @import("type/bit_list.zig").isBitListType;
const h = @import("hashing");
const progressive = @import("type/progressive.zig");

pub fn Hasher(comptime ST: type) type {
    return struct {
        // pub fn hashTreeRoot(allocator: std.mem.Allocator, value: *const ST.Type, out: *[32]u8) !void {}

        pub fn init(allocator: std.mem.Allocator) !HasherData {
            switch (ST.kind) {
                .vector => {
                    if (comptime isBasicType(ST.Element)) {
                        return try HasherData.initCapacity(allocator, ST.chunk_count, null);
                    } else {
                        var children = try allocator.alloc(HasherData, 1);
                        children[0] = try Hasher(ST.Element).init(allocator);
                        return try HasherData.initCapacity(allocator, ST.chunk_count, children);
                    }
                },
                .container => {
                    var children = try allocator.alloc(HasherData, ST.fields.len);
                    inline for (ST.fields, 0..) |field, i| {
                        if (comptime isBasicType(field.type)) {
                            children[i] = try HasherData.initCapacity(allocator, 0, null);
                        } else {
                            children[i] = try Hasher(field.type).init(allocator);
                        }
                    }
                    return try HasherData.initCapacity(allocator, ST.chunk_count, children);
                },
                .list, .progressive_list => {
                    // we don't preallocate here since we need the length
                    const hasher_size = 0;
                    if (comptime isBasicType(ST.Element)) {
                        return try HasherData.initCapacity(allocator, hasher_size, null);
                    } else {
                        var children = try allocator.alloc(HasherData, 1);
                        children[0] = try Hasher(ST.Element).init(allocator);
                        return try HasherData.initCapacity(allocator, hasher_size, children);
                    }
                },
                else => unreachable,
            }
        }

        pub fn hash(scratch: *HasherData, value: *const ST.Type, out: *[32]u8) !void {
            if (comptime isBasicType(ST)) {
                @memset(out, 0);
                switch (ST.kind) {
                    .uint => {
                        std.mem.writeInt(ST.Type, out[0..ST.fixed_size], value.*, .little);
                    },
                    .bool => {
                        out[0] = @intFromBool(value.*);
                    },
                    else => unreachable,
                }
            } else {
                switch (ST.kind) {
                    .list => {
                        const chunk_count = ST.chunkCount(value);
                        try scratch.chunks.ensureTotalCapacity(chunk_count);
                        scratch.chunks.items.len = chunk_count;
                        @memset(scratch.chunks.items, [_]u8{0} ** 32);
                        if (comptime isBitListType(ST)) {
                            const scratch_bytes: []u8 = @ptrCast(scratch.chunks.items[0..chunk_count]);
                            @memcpy(scratch_bytes[0..value.data.items.len], value.data.items);
                        } else if (comptime isBasicType(ST.Element)) {
                            _ = ST.serializeIntoBytes(value, @ptrCast(scratch.chunks.items));
                        } else {
                            for (value.items, 0..) |element, i| {
                                try Hasher(ST.Element).hash(&scratch.children.?[0], &element, &scratch.chunks.items[i]);
                            }
                        }
                        try h.merkleize(scratch.chunks.items, ST.chunk_depth, out);
                        if (ST.Element.kind == .bool) {
                            h.mixInLength(value.bit_len, out);
                        } else {
                            h.mixInLength(value.items.len, out);
                        }
                    },
                    .progressive_list => {
                        const chunk_count = ST.chunkCount(value);
                        try scratch.chunks.resize(chunk_count);
                        @memset(scratch.chunks.items, [_]u8{0} ** 32);
                        if (comptime isBasicType(ST.Element)) {
                            _ = ST.serializeIntoBytes(value, @ptrCast(scratch.chunks.items));
                        } else {
                            for (value.items, 0..) |element, i| {
                                try Hasher(ST.Element).hash(&scratch.children.?[0], &element, &scratch.chunks.items[i]);
                            }
                        }
                        try progressive.merkleizeChunks(scratch.chunks.allocator, scratch.chunks.items, out);
                        h.mixInLength(value.items.len, out);
                    },
                    .vector => {
                        @memset(scratch.chunks.items, [_]u8{0} ** 32);
                        if (comptime isBasicType(ST.Element)) {
                            _ = ST.serializeIntoBytes(value, @ptrCast(scratch.chunks.items));
                        } else {
                            for (value, 0..) |element, i| {
                                try Hasher(ST.Element).hash(&scratch.children.?[0], &element, &scratch.chunks.items[i]);
                            }
                        }
                        try h.merkleize(scratch.chunks.items, ST.chunk_depth, out);
                    },
                    .container => {
                        @memset(scratch.chunks.items, [_]u8{0} ** 32);
                        inline for (ST.fields, 0..) |field, i| {
                            const field_value = @field(value, field.name);
                            try Hasher(field.type).hash(&scratch.children.?[i], &field_value, &scratch.chunks.items[i]);
                        }
                        try h.merkleize(scratch.chunks.items, ST.chunk_depth, out);
                    },
                    else => unreachable,
                }
            }
        }
    };
}

pub const HasherData = struct {
    chunks: std.ArrayList([32]u8),
    children: ?[]HasherData,

    pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize, children: ?[]HasherData) !HasherData {
        var chunks = try std.ArrayList([32]u8).initCapacity(allocator, capacity);
        chunks.expandToCapacity();
        @memset(chunks.items, [_]u8{0} ** 32);
        return HasherData{
            .chunks = chunks,
            .children = children,
        };
    }

    pub fn deinit(self: HasherData, allocator: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |child| {
                child.deinit(allocator);
            }
            allocator.free(children);
        }
        self.chunks.deinit();
    }
};
