const std = @import("std");
const hashing = @import("hashing");

const merkleize = hashing.merkleize;
const maxChunksToDepth = hashing.maxChunksToDepth;
const hashOne = hashing.hashOne;

inline fn hash(a: *const [32]u8, b: *const [32]u8, out: *[32]u8) void {
    hashOne(out, a, b);
}

pub fn merkleizeChunks(allocator: std.mem.Allocator, chunks: []const [32]u8, out: *[32]u8) !void {
    try merkleizeProgressiveImpl(allocator, chunks, 1, out);
}

fn merkleizeProgressiveImpl(
    allocator: std.mem.Allocator,
    chunks: []const [32]u8,
    num_leaves: usize,
    out: *[32]u8,
) !void {
    if (chunks.len == 0) {
        @memset(out, 0);
        return;
    }

    const take = @min(num_leaves, chunks.len);

    var right: [32]u8 = undefined;
    if (take == 0) {
        @memset(&right, 0);
    } else {
        const depth = maxChunksToDepth(num_leaves);
        const even_len = (take + 1) / 2 * 2;

        var tmp = try allocator.alloc([32]u8, even_len);
        defer allocator.free(tmp);
        const zero = [_]u8{0} ** 32;
        @memset(tmp, zero);

        @memcpy(tmp[0..take], chunks[0..take]);
        // merkleize expects [][2][32]u8 (pairs). Reinterpret the tmp leaf array.
        const pairs_len = even_len / 2;
        const pairs: [][2][32]u8 = @as([*][2][32]u8, @ptrCast(tmp.ptr))[0..pairs_len];
        try merkleize(pairs, depth, &right);
    }

    var left: [32]u8 = undefined;
    if (chunks.len > take) {
        try merkleizeProgressiveImpl(allocator, chunks[take..], num_leaves * 4, &left);
    } else {
        @memset(&left, 0);
    }

    hash(&left, &right, out);
}

/// Streamed progressive merkleization over a virtual leaf set.
/// get_leaf(ctx, i, out) must write a 32-byte leaf for index i in [0, total_leaves).
pub fn merkleizeByLeafFn(
    allocator: std.mem.Allocator,
    total_leaves: usize,
    get_leaf: *const fn (ctx: ?*anyopaque, index: usize, out: *[32]u8) anyerror!void,
    ctx: ?*anyopaque,
    out: *[32]u8,
) !void {
    try merkleizeByLeafFnImpl(allocator, 0, total_leaves, 1, get_leaf, ctx, out);
}

fn merkleizeByLeafFnImpl(
    allocator: std.mem.Allocator,
    base: usize,
    remaining: usize,
    num_leaves: usize,
    get_leaf: *const fn (ctx: ?*anyopaque, index: usize, out: *[32]u8) anyerror!void,
    ctx: ?*anyopaque,
    out: *[32]u8,
) !void {
    if (remaining == 0) {
        @memset(out, 0);
        return;
    }

    const take = @min(num_leaves, remaining);

    // Build right branch 'b' by merkleizing the first 'take' leaves at fixed depth.
    var b: [32]u8 = undefined;
    if (take == 0) {
        @memset(&b, 0);
    } else {
        const depth = maxChunksToDepth(num_leaves);
        const even_len = (take + 1) / 2 * 2;

        var tmp = try allocator.alloc([32]u8, even_len);
        defer allocator.free(tmp);
        @memset(tmp, [_]u8{0} ** 32);

        var i: usize = 0;
        while (i < take) : (i += 1) {
            try get_leaf(ctx, base + i, &tmp[i]);
        }
        const pairs_len2 = even_len / 2;
        const pairs2: [][2][32]u8 = @as([*][2][32]u8, @ptrCast(tmp.ptr))[0..pairs_len2];
        try merkleize(pairs2, depth, &b);
    }

    // Left branch 'a' recurses over the tail with capacity x4.
    var a: [32]u8 = undefined;
    if (remaining > take) {
        try merkleizeByLeafFnImpl(allocator, base + take, remaining - take, num_leaves * 4, get_leaf, ctx, &a);
    } else {
        @memset(&a, 0);
    }

    hashOne(out, &a, &b);
}
