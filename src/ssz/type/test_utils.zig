const std = @import("std");
const assert = std.debug.assert;
const isFixedType = @import("type_kind.zig").isFixedType;
const isBitVectorType = @import("bit_vector.zig").isBitVectorType;

/// Tests that two values of the same type `T` hash to the same root.
pub fn expectEqualRoots(comptime T: type, expected: anytype, actual: anytype) !void {
    assert(@TypeOf(expected) == T.Type);
    assert(@TypeOf(actual) == T.Type);

    var expected_buf: [32]u8 = undefined;
    var actual_buf: [32]u8 = undefined;

    try T.hashTreeRoot(&expected, &expected_buf);
    try T.hashTreeRoot(&actual, &actual_buf);

    try std.testing.expectEqualSlices(u8, &expected_buf, &actual_buf);
}

/// Tests that two values of the same type `T` hash to the same root.
///
/// Same as `expectEqualRoots`, except with allocation.
pub fn expectEqualRootsAlloc(comptime T: type, allocator: std.mem.Allocator, expected: anytype, actual: anytype) !void {
    assert(@TypeOf(expected) == T.Type);
    assert(@TypeOf(actual) == T.Type);

    var expected_buf: [32]u8 = undefined;
    var actual_buf: [32]u8 = undefined;

    try T.hashTreeRoot(allocator, &expected, &expected_buf);
    try T.hashTreeRoot(allocator, &actual, &actual_buf);

    try std.testing.expectEqualSlices(u8, &expected_buf, &actual_buf);
}
