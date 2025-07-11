const std = @import("std");
const TestCase = @import("common.zig").TypeTestCase;
const UintType = @import("ssz").UintType;
const BoolType = @import("ssz").BoolType;
const ByteVectorType = @import("ssz").ByteVectorType;
const FixedContainerType = @import("ssz").FixedContainerType;
const VariableContainerType = @import("ssz").VariableContainerType;
const FixedListType = @import("ssz").FixedListType;

test "ContainerType" {
    const test_cases = [_]TestCase{
        TestCase{
            .id = "empty",
            .serializedHex = "0x00000000000000000000000000000000",
            .json =
            \\{"a":"0","b":"0"}
            ,
            .rootHex = "0x0000000000000000000000000000000000000000000000000000000000000000",
        },
        TestCase{
            .id = "simple",
            .serializedHex = "0x01000000000000000000000000000000",
            .json =
            \\{"a":"1","b":"0"}
            ,
            .rootHex = "0x5c597e77f879e249af95fe543cf5f4dd16b686948dc719707445a32a77ff6266",
        },
    };

    const allocator = std.testing.allocator;

    const Container = FixedContainerType(struct {
        a: UintType(64),
        b: UintType(64),
    });

    const TypeTest = @import("common.zig").typeTest(Container);

    for (test_cases[0..]) |*tc| {
        try TypeTest.run(allocator, tc);
    }
}

test "ContainerType with FixedListType(uint64, 128) and uint64" {
    const allocator = std.testing.allocator;

    const Container = VariableContainerType(struct {
        a: FixedListType(UintType(64), 128),
        b: UintType(64),
    });

    const TypeTest = @import("common.zig").typeTest(Container);

    const test_cases = [_]TestCase{
        TestCase{
            .id = "empty",
            .serializedHex = "0x0c0000000000000000000000",
            .json =
            \\{"a":[],"b":"0"}
            ,
            .rootHex = "0x0000000000000000000000000000000000000000000000000000000000000000",
        },
        TestCase{
            .id = "simple",
            .serializedHex = "0x0c00000000000000000000000100000000000000",
            .json =
            \\{"a":["1"],"b":"0"}
            ,
            .rootHex = "0x5c597e77f879e249af95fe543cf5f4dd16b686948dc719707445a32a77ff6266",
        },
    };

    for (test_cases[0..]) |*tc| {
        try TypeTest.run(allocator, tc);
    }
}

test "FixedContainerType equals" {
    const Container = FixedContainerType(struct {
        slot: UintType(64),
        root: ByteVectorType(32),
        active: BoolType(),
    });

    var a: Container.Type = undefined;
    var b: Container.Type = undefined;
    var c: Container.Type = undefined;

    a.slot = 42;
    a.root = [_]u8{1} ** 32;
    a.active = true;

    b.slot = 42;
    b.root = [_]u8{1} ** 32;
    b.active = true;

    c.slot = 43; // Different slot
    c.root = [_]u8{1} ** 32;
    c.active = true;

    try std.testing.expect(Container.equals(&a, &b));
    try std.testing.expect(!Container.equals(&a, &c));
}

test "VariableContainerType equals" {
    const allocator = std.testing.allocator;
    const Container = VariableContainerType(struct {
        list1: FixedListType(UintType(8), 32),
        list2: FixedListType(UintType(8), 32),
        value: UintType(64),
    });

    var a: Container.Type = undefined;
    var b: Container.Type = undefined;
    var c: Container.Type = undefined;

    a.list1 = FixedListType(UintType(8), 32).Type.empty;
    a.list2 = FixedListType(UintType(8), 32).Type.empty;
    a.value = 100;

    b.list1 = FixedListType(UintType(8), 32).Type.empty;
    b.list2 = FixedListType(UintType(8), 32).Type.empty;
    b.value = 100;

    c.list1 = FixedListType(UintType(8), 32).Type.empty;
    c.list2 = FixedListType(UintType(8), 32).Type.empty;
    c.value = 101; // Different value

    defer a.list1.deinit(allocator);
    defer a.list2.deinit(allocator);
    defer b.list1.deinit(allocator);
    defer b.list2.deinit(allocator);
    defer c.list1.deinit(allocator);
    defer c.list2.deinit(allocator);

    try a.list1.appendSlice(allocator, &[_]u8{ 1, 2, 3 });
    try a.list2.appendSlice(allocator, &[_]u8{ 4, 5, 6 });

    try b.list1.appendSlice(allocator, &[_]u8{ 1, 2, 3 });
    try b.list2.appendSlice(allocator, &[_]u8{ 4, 5, 6 });

    try c.list1.appendSlice(allocator, &[_]u8{ 1, 2, 3 });
    try c.list2.appendSlice(allocator, &[_]u8{ 4, 5, 6 });

    try std.testing.expect(Container.equals(&a, &b));
    try std.testing.expect(!Container.equals(&a, &c));
}
