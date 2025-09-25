const std = @import("std");
const merkleize = @import("hashing").merkleize;
const mixInAux = @import("hashing").mixInAux;
const hashOne = @import("hashing").hashOne;
const Depth = @import("hashing").Depth;
const Node = @import("persistent_merkle_tree").Node;
const Gindex = @import("persistent_merkle_tree").Gindex;

pub const std_options = .{ .log_level = .debug };
pub const log_scope_levels = &.{.{ .scope = .pgl, .level = .debug }};
const log = std.log.scoped(.pgl);

const base_count = 1;
const scaling_factor = 4;

pub fn chunkGindex(chunk_i: usize) Gindex {
    const subtree_i = subtreeIndex(chunk_i);
    var i = subtree_i;
    var gindex: Gindex.Uint = 1;
    var subtree_starting_index = 0;
    while (i > 0) {
        i -= 1;
        gindex *= 2;
        subtree_starting_index += subtreeLength(i);
    }

    gindex += 1;

    gindex *= try std.math.powi(usize, 2, subtreeDepth(subtree_i));

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

pub fn merkleizeChunks(allocator: std.mem.Allocator, chunks: [][32]u8, out: *[32]u8) !void {
    if (chunks.len == 0) {
        out.* = [_]u8{0} ** 32;
        return;
    }

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

            const depth = subtreeDepth(subtree_i);
            if (depth == 0) {
                subtree_roots[subtree_i] = final_subtree_chunks[0];
            } else {
                try merkleize(@ptrCast(final_subtree_chunks), depth, &subtree_roots[subtree_i]);
            }
        } else {
            const depth = subtreeDepth(subtree_i);
            if (depth == 0) {
                subtree_roots[subtree_i] = c[0];
            } else {
                try merkleize(@ptrCast(c[0..subtree_length]), depth, &subtree_roots[subtree_i]);
            }

            c = c[subtree_length..];
            subtree_length *= scaling_factor;
        }
    }
    out.* = [_]u8{0} ** 32;
    var subtree_i = subtree_count;
    while (subtree_i > 0) {
        subtree_i -= 1;
        hashOne(
            out,
            out,
            &subtree_roots[subtree_i],
        );
    }
}

pub fn getNodes(pool: *Node.Pool, root: Node.Id, out: []Node.Id) !void {
    const subtree_count = subtreeIndex(out.len);

    errdefer {
    }

    var n = root;
    errdefer {
    }

    var l: usize = 0;
    for (0..subtree_count) |subtree_i| {
        errdefer {
        }

        const subtree_length = @min(subtreeLength(subtree_i), out.len - l);
        const subtree_depth = subtreeDepth(subtree_i);
        const subtree_root = n.getRight(pool) catch |err| {
            if (@intFromEnum(n) == 0) {
                for (l..l + subtree_length) |pos| {
                    if (pos < out.len) {
                        out[pos] = @enumFromInt(0);
                    }
                }
                l += subtree_length;
                n = @enumFromInt(0);
                continue;
            }
            return err;
        };
        if (subtree_depth == 0) {
            if (subtree_length != 1) {
                return error.InvalidSubtreeLength;
            }
            out[l] = subtree_root;
        } else {
            subtree_root.getNodesAtDepth(pool, subtree_depth, 0, out[l .. l + subtree_length]) catch |err| {
                return err;
            };
        }
        l += subtree_length;
        n = n.getLeft(pool) catch |err| {
            return err;
        };
    }

    if (!std.mem.eql(u8, &n.getRoot(pool).*, &[_]u8{0} ** 32)) {
        return error.InvalidTerminatorNode;
    }
}

pub fn fillWithContents(allocator: std.mem.Allocator, pool: *Node.Pool, nodes: []Node.Id, should_ref: bool) !Node.Id {
    const subtree_count = subtreeIndex(nodes.len);

    errdefer {
    }

    var n: Node.Id = @enumFromInt(0);

    var subtree_starts = std.ArrayList(usize).init(allocator);
    defer subtree_starts.deinit();
    var pos: usize = 0;
    for (0..subtree_count) |subtree_i| {
        try subtree_starts.append(pos);
        pos += @min(subtreeLength(subtree_i), nodes.len - pos);
    }

    for (0..subtree_count) |i| {
        const subtree_i = subtree_count - 1 - i;
        const subtree_depth = subtreeDepth(subtree_i);
        const l = subtree_starts.items[subtree_i];
        const subtree_length = @min(subtreeLength(subtree_i), nodes.len - l);

        errdefer {
        }

        const subtree_root = Node.fillWithContents(pool, nodes[l .. l + subtree_length], subtree_depth, false) catch |err| {
            return err;
        };

        n = pool.createBranch(
            n,
            subtree_root,
            should_ref,
        ) catch |err| {
            return err;
        };
    }

    return n;
}
