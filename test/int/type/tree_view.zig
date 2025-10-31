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
    var cp_view = try ssz.TreeView(Checkpoint).init(std.testing.allocator, &pool, root_node);
    defer cp_view.deinit();

    // get field "epoch"
    try std.testing.expectEqual(42, try cp_view.getField("epoch"));

    // get field "root"
    var root_view = try cp_view.getField("root");
    var root = [_]u8{0} ** 32;
    const RootView = ssz.TreeView(Checkpoint).Field("root");
    try RootView.SszType.tree.toValue(root_view.data.root, &pool, root[0..]);
    try std.testing.expectEqualSlices(u8, ([_]u8{1} ** 32)[0..], root[0..]);

    // modify field "epoch"
    try cp_view.setField("epoch", 100);
    try std.testing.expectEqual(100, try cp_view.getField("epoch"));

    // modify field "root"
    var new_root = [_]u8{2} ** 32;
    const new_root_node = try RootView.SszType.tree.fromValue(&pool, &new_root);
    const new_root_view = try RootView.init(std.testing.allocator, &pool, new_root_node);
    try cp_view.setField("root", new_root_view);

    // confirm "root" has been modified
    root_view = try cp_view.getField("root");
    try RootView.SszType.tree.toValue(root_view.data.root, &pool, root[0..]);
    try std.testing.expectEqualSlices(u8, ([_]u8{2} ** 32)[0..], root[0..]);

    // commit and check hash_tree_root
    try cp_view.commit();
    var htr_from_value: [32]u8 = undefined;
    const expected_checkpoint: Checkpoint.Type = .{
        .epoch = 100,
        .root = [_]u8{2} ** 32,
    };
    try Checkpoint.hashTreeRoot(&expected_checkpoint, &htr_from_value);

    var htr_from_tree: [32]u8 = undefined;
    try cp_view.hashTreeRoot(&htr_from_tree);

    try std.testing.expectEqualSlices(
        u8,
        &htr_from_value,
        &htr_from_tree,
    );
}

test "TreeView vector of basics" {
    const Node = @import("persistent_merkle_tree").Node;
    var pool = try Node.Pool.init(std.testing.allocator, 1000);
    defer pool.deinit();

    const Uint64 = ssz.UintType(64);
    const Vector = ssz.FixedVectorType(Uint64, 6);

    var initial: Vector.Type = [_]u64{ 10, 20, 30, 40, 50, 60 };
    const root_node = try Vector.tree.fromValue(&pool, &initial);

    var vec_view = try ssz.TreeView(Vector).init(std.testing.allocator, &pool, root_node);
    defer vec_view.deinit();

    try std.testing.expectEqual(@as(u64, 10), try vec_view.getElement(0));
    try std.testing.expectEqual(@as(u64, 60), try vec_view.getElement(5));

    try vec_view.setElement(2, 333);
    try vec_view.setElement(5, 999);

    try std.testing.expectEqual(@as(u64, 333), try vec_view.getElement(2));
    try std.testing.expectEqual(@as(u64, 999), try vec_view.getElement(5));

    try vec_view.commit();

    var expected: Vector.Type = initial;
    expected[2] = 333;
    expected[5] = 999;

    var expected_root: [32]u8 = undefined;
    try Vector.hashTreeRoot(&expected, &expected_root);

    var view_root: [32]u8 = undefined;
    try vec_view.hashTreeRoot(&view_root);

    try std.testing.expectEqualSlices(u8, &expected_root, &view_root);
}

test "TreeView vector of bool basics" {
    const Node = @import("persistent_merkle_tree").Node;
    var pool = try Node.Pool.init(std.testing.allocator, 1000);
    defer pool.deinit();

    const Bool = ssz.BoolType();
    const Vector = ssz.FixedVectorType(Bool, 40);

    var initial: Vector.Type = [_]bool{false} ** 40;
    initial[1] = true;
    initial[5] = true;
    initial[33] = true;
    const root_node = try Vector.tree.fromValue(&pool, &initial);

    var vec_view = try ssz.TreeView(Vector).init(std.testing.allocator, &pool, root_node);
    defer vec_view.deinit();

    try std.testing.expectEqual(false, try vec_view.getElement(0));
    try std.testing.expectEqual(true, try vec_view.getElement(1));
    try std.testing.expectEqual(true, try vec_view.getElement(33));

    try vec_view.setElement(0, true);
    try vec_view.setElement(33, false);
    try vec_view.setElement(35, true);

    try std.testing.expectEqual(true, try vec_view.getElement(0));
    try std.testing.expectEqual(false, try vec_view.getElement(33));
    try std.testing.expectEqual(true, try vec_view.getElement(35));

    try vec_view.commit();

    var expected: Vector.Type = initial;
    expected[0] = true;
    expected[33] = false;
    expected[35] = true;

    var expected_root: [32]u8 = undefined;
    try Vector.hashTreeRoot(&expected, &expected_root);

    var view_root: [32]u8 = undefined;
    try vec_view.hashTreeRoot(&view_root);

    try std.testing.expectEqualSlices(u8, &expected_root, &view_root);
}
