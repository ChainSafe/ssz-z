const std = @import("std");
const TestCase = @import("common.zig").TypeTestCase;
const UintType = @import("ssz").UintType;
const FixedVectorType = @import("ssz").FixedVectorType;

const testCases = [_]TestCase{
    TestCase{
        .id = "8 values",
        .serializedHex = "0xa086010000000000400d030000000000e093040000000000801a060000000000a086010000000000400d030000000000e093040000000000801a060000000000",
        .json =
        \\["100000","200000","300000","400000","100000","200000","300000","400000"]
        ,
        .rootHex = "0xdd5160dd98e6daa77287c8940decad4eaa14dc98b99285da06ba5479cd570007",
    },
};

test "valid test for VectorBasicType" {
    const allocator = std.testing.allocator;

    // uint of 8 bytes = u64
    const Uint = UintType(64);
    const Vector = FixedVectorType(Uint, 8);

    const TypeTest = @import("common.zig").typeTest(Vector);

    for (testCases[0..]) |*tc| {
        try TypeTest.run(allocator, tc);
    }
}

test "FixedVectorType equals" {
    const Vec = FixedVectorType(UintType(8), 4);

    var a: Vec.Type = [_]u8{ 1, 2, 3, 4 };
    var b: Vec.Type = [_]u8{ 1, 2, 3, 4 };
    var c: Vec.Type = [_]u8{ 1, 2, 3, 5 };

    try std.testing.expect(Vec.equals(&a, &b));
    try std.testing.expect(!Vec.equals(&a, &c));
}
