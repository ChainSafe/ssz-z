const std = @import("std");
const toRootHex = @import("util").toRootHex;
const fromHex = @import("util").fromHex;
const TestCase = @import("common.zig").TypeTestCase;
const ByteVectorType = @import("ssz").ByteVectorType;
const FixedVectorType = @import("ssz").FixedVectorType;
const UintType = @import("ssz").UintType;
const FixedContainerType = @import("ssz").FixedContainerType;

test "VectorCompositeType of Root" {
    const test_cases = [_]TestCase{
        TestCase{
            .id = "4 roots",
            .serializedHex = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            .json =
            \\["0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", "0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc", "0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"]
            ,
            .rootHex = "0x56019bafbc63461b73e21c6eae0c62e8d5b8e05cb0ac065777dc238fcf9604e6",
        },
    };

    const allocator = std.testing.allocator;
    const ByteVector = ByteVectorType(32);
    const Vector = FixedVectorType(ByteVector, 4);

    const TypeTest = @import("common.zig").typeTest(Vector);

    for (test_cases[0..]) |*tc| {
        try TypeTest.run(allocator, tc);
    }
}

test "VectorCompositeType of Container" {
    const test_cases = [_]TestCase{
        TestCase{
            .id = "4 containers",
            .serializedHex = "0x0100000000000000000200000000000000030000000000000004000000000000000500000000000000060000000000000007000000000000000800000000000000",
            .json =
            \\[{"a": "1", "b": "2"}, {"a": "3", "b": "4"}, {"a": "5", "b": "6"}, {"a": "7", "b": "8"}]
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
    const Vector = FixedVectorType(Container, 4);

    const TypeTest = @import("common.zig").typeTest(Vector);

    for (test_cases[0..]) |*tc| {
        try TypeTest.run(allocator, tc);
    }
}
