const std = @import("std");
const merkleize = @import("hashing").merkleize;
const mixInAux = @import("hashing").mixInAux;
const hashOne = @import("hashing").hashOne;
const Depth = @import("hashing").Depth;
const Node = @import("persistent_merkle_tree").Node;
const Gindex = @import("persistent_merkle_tree").Gindex;

const base_count = 1;
const scaling_factor = 4;

// Given a chunk index, return the gindex based on the progressive merklization scheme defined by https://eips.ethereum.org/EIPS/eip-7916
pub fn chunkGindex(chunk_i: usize) Gindex {
    const subtree_i = subtreeIndex(chunk_i);
    var i = subtree_i;
    var gindex: Gindex.Uint = 1;
    var subtree_starting_index = 0;
    // navigate down to the successor root at chunk_i
    // also track the starting index at that level's subtree
    while (i > 0) {
        i -= 1;
        gindex *= 2;
        subtree_starting_index += subtreeLength(i);
    }

    // navigate to that level's subtree
    gindex += 1;

    // navigate to the subtree starting leaf
    gindex *= try std.math.powi(usize, 2, subtreeDepth(subtree_i));

    // navigate to the chunk index within the subtree
    gindex += chunk_i - subtree_starting_index;
    return @enumFromInt(gindex);
}

pub fn subtreeIndex(chunk_i: usize) usize {
    var left: usize = chunk_i;
    var subtree_length: usize = base_count;
    var subtree_i: usize = 0;
    while (left > 0) {
        left -|= subtree_length;
        subtree_length *= scaling_factor;
        subtree_i += 1;
    }
    return subtree_i;
}

pub fn subtreeLength(subtree_i: usize) usize {
    return std.math.pow(usize, scaling_factor, subtree_i);
}

pub fn subtreeDepth(subtree_i: usize) Depth {
    return @intCast(subtree_i * std.math.log2_int(usize, scaling_factor));
}

/// merkleize chunks using the progressive merklization scheme defined by https://eips.ethereum.org/EIPS/eip-7916
pub fn merkleizeChunks(allocator: std.mem.Allocator, chunks: [][32]u8, out: *[32]u8) !void {
    const subtree_count = subtreeIndex(chunks.len);
    const subtree_roots = try allocator.alloc([32]u8, subtree_count);
    defer allocator.free(subtree_roots);

    var c = chunks;
    var subtree_length: usize = base_count;
    for (0..subtree_count) |subtree_i| {
        if (c.len <= subtree_length) {
            const final_subtree_chunks = try allocator.alloc([32]u8, subtree_length);
            defer allocator.free(final_subtree_chunks);

            @memcpy(final_subtree_chunks[0..c.len], c);
            @memset(final_subtree_chunks[c.len..], [_]u8{0} ** 32);
            try merkleize(@ptrCast(final_subtree_chunks), subtreeDepth(subtree_i), &subtree_roots[subtree_i]);
        } else {
            const next_size = subtree_length * scaling_factor;
            try merkleize(@ptrCast(c[0..subtree_length]), subtreeDepth(subtree_i), &subtree_roots[subtree_i]);
            c = c[subtree_length..];
            subtree_length = next_size;
        }
    }
    out.* = [_]u8{0} ** 32;
    var subtree_i = subtree_count;
    while (subtree_i > 0) {
        subtree_i -= 1;
        hashOne(
            out,
            &subtree_roots[subtree_i],
            out,
        );
    }
}

/// Get `out.len` nodes in a single traversal from a tree that uses the progressive merklization scheme defined by https://eips.ethereum.org/EIPS/eip-7916
pub fn getNodes(pool: *Node.Pool, root: Node.Id, out: []Node.Id) !void {
    const subtree_count = subtreeIndex(out.len);
    var n = root;
    var l: usize = 0;
    for (0..subtree_count) |subtree_i| {
        const subtree_root = try n.getLeft(pool);
        const subtree_length = @min(subtreeLength(subtree_i), out.len - l);
        const subtree_depth = subtreeDepth(subtree_i);
        try subtree_root.getNodesAtDepth(pool, subtree_depth, 0, out[l .. l + subtree_length]);
        l += subtree_length;
        n = try n.getRight(pool);
    }
    if (!std.mem.eql(u8, &n.getRoot(pool).*, &[_]u8{0} ** 32)) {
        return error.InvalidTerminatorNode;
    }
}

pub fn fillWithContents(pool: *Node.Pool, nodes: []Node.Id, should_ref: bool) !Node.Id {
    const subtree_count = subtreeIndex(nodes.len);
    var l: usize = 0;
    var n: Node.Id = @enumFromInt(0);
    for (0..subtree_count) |subtree_i| {
        const subtree_depth = subtreeDepth(subtree_i);
        const subtree_length = @min(subtreeLength(subtree_i), nodes.len - l);
        const subtree_root = try Node.fillWithContents(pool, nodes[l .. l + subtree_length], subtree_depth, false);
        l += subtree_length;
        n = try pool.createBranch(
            subtree_root,
            n,
            should_ref,
        );
    }
    return n;
}
