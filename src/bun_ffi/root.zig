const std = @import("std");
const Node = @import("persistent_merkle_tree").Node;
const consensus_types = @import("consensus_types");

var gpa = std.heap.DebugAllocator(.{}).init;
const allocator = gpa.allocator();
var pool: Node.Pool = undefined;

export fn pool_init(size: c_uint) c_uint {
    pool = Node.Pool.init(
        allocator,
        size,
    ) catch |e| return @intFromError(e);
    return 0;
}

export fn pool_deinit() void {
    pool.deinit();
}

////

export fn node_ref(node_id: c_uint) c_uint {
    pool.ref(@enumFromInt(node_id)) catch |e| return @intFromError(e);
    return 0;
}

export fn node_unref(node_id: c_uint) void {
    pool.unref(@enumFromInt(node_id));
}

export fn node_get_root(node_id: c_uint, out: [*c]u8) void {
    const node: Node.Id = @enumFromInt(node_id);
    @memcpy(out, node.getRoot(&pool));
}

export fn node_get_node(node_id: c_uint, gindex: c_uint) c_int {
    const node: Node.Id = @enumFromInt(node_id);
    return @intCast(@intFromEnum(node.getNode(&pool, @enumFromInt(gindex)) catch return -1));
}

export fn node_get_left(node_id: c_uint) c_int {
    const node: Node.Id = @enumFromInt(node_id);
    return @intCast(@intFromEnum(node.getLeft(&pool) catch return -1));
}

export fn node_get_right(node_id: c_uint) c_int {
    const node: Node.Id = @enumFromInt(node_id);
    return @intCast(@intFromEnum(node.getRight(&pool) catch return -1));
}

////

export fn phase0_checkpoint_create_default_tree() c_int {
    const Checkpoint = consensus_types.phase0.Checkpoint;
    return @intCast(@intFromEnum(Checkpoint.tree.fromValue(
        &pool,
        &Checkpoint.default_value,
    ) catch return -1));
}
