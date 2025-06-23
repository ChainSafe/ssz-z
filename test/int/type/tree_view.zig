const std = @import("std");
const ssz = @import("ssz");

const Checkpoint = ssz.FixedContainerType(struct {
    epoch: ssz.UintType(64),
    root: ssz.ByteVectorType(32),
});

test "TreeView" {
    const Node = @import("persistent_merkle_tree").Node;
    var pool = try Node.Pool.init(std.testing.allocator, 1000);
    defer pool.deinit();
    const checkpoint: Checkpoint.Type = .{
        .epoch = 42,
        .root = [_]u8{1} ** 32,
    };

    const root_node = try Checkpoint.tree.fromValue(&pool, &checkpoint);
    var view = try ssz.TreeView(Checkpoint).init(std.testing.allocator, &pool, root_node);
    defer view.deinit();

    // get field "epoch"
    try std.testing.expectEqual(42, try view.getField("epoch"));

    // get field "root"
    var root_view = try view.getField("root");
    var root = [_]u8{0} ** 32;
    const RootView = ssz.TreeView(Checkpoint).Field("root");
    try RootView.SszType.tree.toValue(root_view.data.root, &pool, root[0..]);
    try std.testing.expectEqualSlices(u8, ([_]u8{1} ** 32)[0..], root[0..]);

    // modify field "epoch"
    try view.setField("epoch", 100);
    try std.testing.expectEqual(100, try view.getField("epoch"));

    // modify field "root"
    var new_root = [_]u8{2} ** 32;
    const new_root_node = try RootView.SszType.tree.fromValue(&pool, &new_root);
    const new_root_view = try RootView.init(std.testing.allocator, &pool, new_root_node);
    try view.setField("root", new_root_view);

    // confirm "root" has been modified
    root_view = try view.getField("root");
    try RootView.SszType.tree.toValue(root_view.data.root, &pool, root[0..]);
    try std.testing.expectEqualSlices(u8, ([_]u8{2} ** 32)[0..], root[0..]);

    // commit and check hash_tree_root
    // TODO: fix setNodes() api
    // try view.commit();
    // var htr_from_value: [32]u8 = undefined;
    // const expected_checkpoint: Checkpoint.Type = .{
    //     .epoch = 100,
    //     .root = [_]u8{2} ** 32,
    // };
    // try Checkpoint.hashTreeRoot(&expected_checkpoint, &htr_from_value);

    // var htr_from_tree: [32]u8 = undefined;
    // try view.hashTreeRoot(&htr_from_tree);

    // try std.testing.expectEqualSlices(
    //     u8,
    //     &htr_from_value,
    //     &htr_from_tree,
    // );
}
