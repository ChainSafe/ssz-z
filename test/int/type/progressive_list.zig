const std = @import("std");
const ssz = @import("ssz");
const types = ssz.types;
const TestCase = @import("common.zig").TypeTestCase;

test "ProgressiveListType(u64) vector tests" {
    std.debug.print("PROBE: progressive test starting\n", .{});
    const a = std.testing.allocator;
    const U64 = types.UintType(64);
    const PList = types.ProgressiveListType(U64, 1024);
    const TypeTest = @import("common.zig").typeTest(PList);

    const testCases = [_]TestCase{
        TestCase{ .id = "empty", .serializedHex = "0x", .json = "[]", .rootHex = "0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b" },
        TestCase{ .id = "4 values", .serializedHex = "0xa086010000000000400d030000000000e093040000000000801a060000000000", .json = "[\"100000\",\"200000\",\"300000\",\"400000\"]", .rootHex = "0x38fc50464faabda97fefa5c8d82c429ab1266e2ca58a375cac08f255cf78b82c" },
        TestCase{ .id = "8 values", .serializedHex = "0xa086010000000000400d030000000000e093040000000000801a060000000000a086010000000000400d030000000000e093040000000000801a060000000000", .json = "[\"100000\",\"200000\",\"300000\",\"400000\",\"100000\",\"200000\",\"300000\",\"400000\"]", .rootHex = "0xfd8b579369890fb42a953a758d25253689be141472fa865f74c14fc8f4853957" },
    };

    for (testCases[0..]) |*tc| {
        try TypeTest.run(a, tc);
    }
}
