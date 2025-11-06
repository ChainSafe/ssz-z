const std = @import("std");
const Allocator = std.mem.Allocator;

const hashOne = @import("hashing").hashOne;
const GindexUint = @import("hashing").GindexUint;
const Node = @import("Node.zig");
const Gindex = @import("gindex.zig").Gindex;

pub const Error = error{
    /// Allocator or pool could not reserve enough memory.
    OutOfMemory,
    /// Provided generalized index is not part of the binary tree (must be >= 1).
    InvalidGindex,
    /// Navigation toward the requested index hit a leaf before reaching the expected depth.
    InvalidNavigation,
    /// Witness list length does not match the gindex path length.
    InvalidWitnessLength,
};

pub const SingleProof = struct {
    leaf: [32]u8,
    witnesses: [][32]u8,

    pub fn deinit(self: *SingleProof, allocator: Allocator) void {
        allocator.free(self.witnesses);
        self.* = undefined;
    }
};

/// Produces a single Merkle proof for the node at `gindex`.
pub fn createSingleProof(
    allocator: Allocator,
    pool: *Node.Pool,
    root: Node.Id,
    gindex: Gindex,
) Error!SingleProof {
    if (@intFromEnum(gindex) < 1) {
        return error.InvalidGindex;
    }

    const path_len = gindex.pathLen();
    var witnesses = try allocator.alloc([32]u8, path_len);
    errdefer allocator.free(witnesses);

    if (path_len == 0) {
        return SingleProof{
            .leaf = root.getRoot(pool).*,
            .witnesses = witnesses,
        };
    }

    var node_id = root;
    var path = gindex.toPath();

    const witness_offset_from_leaf: usize = 1;

    for (0..path_len) |depth_idx| {
        const witness_index = path_len - witness_offset_from_leaf - depth_idx;

        if (path.left()) {
            const right_id = node_id.getRight(pool) catch {
                return error.InvalidNavigation;
            };
            witnesses[witness_index] = right_id.getRoot(pool).*;
            node_id = node_id.getLeft(pool) catch {
                return error.InvalidNavigation;
            };
        } else {
            const left_id = node_id.getLeft(pool) catch {
                return error.InvalidNavigation;
            };
            witnesses[witness_index] = left_id.getRoot(pool).*;
            node_id = node_id.getRight(pool) catch {
                return error.InvalidNavigation;
            };
        }

        path.next();
    }

    return SingleProof{
        .leaf = node_id.getRoot(pool).*,
        .witnesses = witnesses,
    };
}

/// Build a fresh node tree from a single Merkle proof.
pub fn createNodeFromSingleProof(
    pool: *Node.Pool,
    gindex: Gindex,
    leaf: [32]u8,
    witnesses: []const [32]u8,
) (Node.Error || Error)!Node.Id {
    if (@intFromEnum(gindex) < 1) {
        return error.InvalidGindex;
    }

    const path_len = gindex.pathLen();
    if (witnesses.len != path_len) {
        return error.InvalidWitnessLength;
    }

    var node_id = try pool.createLeaf(&leaf, false);
    var index_value: GindexUint = @intFromEnum(gindex);

    for (witnesses) |witness| {
        const sibling_id = try pool.createLeaf(&witness, false);
        if ((index_value & 1) == 0) {
            node_id = try pool.createBranch(node_id, sibling_id, false);
        } else {
            node_id = try pool.createBranch(sibling_id, node_id, false);
        }
        index_value >>= 1;
    }

    // Raise the reference count so callers own the result.
    try pool.ref(node_id);
    return node_id;
}
