const std = @import("std");
const TestCase = @import("common.zig").TypeTestCase;
const UintType = @import("ssz").UintType;
const ByteVectorType = @import("ssz").ByteVectorType;
const FixedListType = @import("ssz").FixedListType;
const VariableListType = @import("ssz").VariableListType;
const FixedContainerType = @import("ssz").FixedContainerType;

test "ListCompositeType of Root" {
    const test_cases = [_]TestCase{
        TestCase{
            .id = "4 roots",
            .serializedHex = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            .json =
            \\["0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc","0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"]
            ,
            .rootHex = "0x56019bafbc63461b73e21c6eae0c62e8d5b8e05cb0ac065777dc238fcf9604e6",
        },
    };

    const allocator = std.testing.allocator;
    const ByteVector = ByteVectorType(32);
    const List = FixedListType(ByteVector, 4);

    const TypeTest = @import("common.zig").typeTest(List);

    for (test_cases[0..]) |*tc| {
        try TypeTest.run(allocator, tc);
    }
}

test "ListCompositeType of Container" {
    const test_cases = [_]TestCase{
        TestCase{
            .id = "4 containers",
            .serializedHex = "0x01000000000000000200000000000000030000000000000004000000000000000500000000000000060000000000000007000000000000000800000000000000",
            .json =
            \\[{"a":"1","b":"2"},{"a":"3","b":"4"},{"a":"5","b":"6"},{"a":"7","b":"8"}]
            ,
            .rootHex = "0x0000000000000000000000000000000000000000000000000000000000000000",
        },
    };

    const allocator = std.testing.allocator;
    const Uint = UintType(64);
    const Container = FixedContainerType(struct {
        a: Uint,
        b: Uint,
    });
    const List = FixedListType(Container, 4);

    const TypeTest = @import("common.zig").typeTest(List);

    for (test_cases[0..]) |*tc| {
        try TypeTest.run(allocator, tc);
    }
}

test "VariableListType of FixedList" {
    const test_cases = [_]TestCase{
        TestCase{
            .id = "empty",
            .serializedHex = "0x",
            .json =
            \\[]
            ,
            .rootHex = "0x7a0501f5957bdf9cb3a8ff4966f02265f968658b7a9c62642cba1165e86642f5",
        },
        TestCase{
            .id = "2 full values",
            .serializedHex = "0x080000000c0000000100020003000400",
            .json =
            \\[["1","2"],["3","4"]]
            ,
            .rootHex = "0x0000000000000000000000000000000000000000000000000000000000000000",
        },
        TestCase{
            .id = "2 empty values",
            .serializedHex = "0x0800000008000000",
            .json =
            \\[[],[]]
            ,
            .rootHex = "0xe839a22714bda05923b611d07be93b4d707027d29fd9eef7aa864ed587e462ec",
        },
    };

    const allocator = std.testing.allocator;
    const FixedList = FixedListType(UintType(16), 2);
    const List = VariableListType(FixedList, 2);

    const TypeTest = @import("common.zig").typeTest(List);

    for (test_cases[0..]) |*tc| {
        try TypeTest.run(allocator, tc);
    }
}
