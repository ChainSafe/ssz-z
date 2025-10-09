const ssz = @import("ssz");

// the names of decls here must match the generic test subdirectories
// (don't change the names)

// basic_vector
pub const vec_bool_0 = ssz.FixedVectorType(ssz.BoolType(), 0);
pub const vec_bool_1 = ssz.FixedVectorType(ssz.BoolType(), 1);
pub const vec_bool_2 = ssz.FixedVectorType(ssz.BoolType(), 2);
pub const vec_bool_3 = ssz.FixedVectorType(ssz.BoolType(), 3);
pub const vec_bool_4 = ssz.FixedVectorType(ssz.BoolType(), 4);
pub const vec_bool_5 = ssz.FixedVectorType(ssz.BoolType(), 5);
pub const vec_bool_8 = ssz.FixedVectorType(ssz.BoolType(), 8);
pub const vec_bool_16 = ssz.FixedVectorType(ssz.BoolType(), 16);
pub const vec_bool_31 = ssz.FixedVectorType(ssz.BoolType(), 31);
pub const vec_bool_512 = ssz.FixedVectorType(ssz.BoolType(), 512);
pub const vec_bool_513 = ssz.FixedVectorType(ssz.BoolType(), 513);
pub const vec_uint8_0 = ssz.FixedVectorType(ssz.UintType(8), 0);
pub const vec_uint8_1 = ssz.FixedVectorType(ssz.UintType(8), 1);
pub const vec_uint8_2 = ssz.FixedVectorType(ssz.UintType(8), 2);
pub const vec_uint8_3 = ssz.FixedVectorType(ssz.UintType(8), 3);
pub const vec_uint8_4 = ssz.FixedVectorType(ssz.UintType(8), 4);
pub const vec_uint8_5 = ssz.FixedVectorType(ssz.UintType(8), 5);
pub const vec_uint8_8 = ssz.FixedVectorType(ssz.UintType(8), 8);
pub const vec_uint8_16 = ssz.FixedVectorType(ssz.UintType(8), 16);
pub const vec_uint8_31 = ssz.FixedVectorType(ssz.UintType(8), 31);
pub const vec_uint8_512 = ssz.FixedVectorType(ssz.UintType(8), 512);
pub const vec_uint8_513 = ssz.FixedVectorType(ssz.UintType(8), 513);
pub const vec_uint16_0 = ssz.FixedVectorType(ssz.UintType(16), 0);
pub const vec_uint16_1 = ssz.FixedVectorType(ssz.UintType(16), 1);
pub const vec_uint16_2 = ssz.FixedVectorType(ssz.UintType(16), 2);
pub const vec_uint16_3 = ssz.FixedVectorType(ssz.UintType(16), 3);
pub const vec_uint16_4 = ssz.FixedVectorType(ssz.UintType(16), 4);
pub const vec_uint16_5 = ssz.FixedVectorType(ssz.UintType(16), 5);
pub const vec_uint16_8 = ssz.FixedVectorType(ssz.UintType(16), 8);
pub const vec_uint16_16 = ssz.FixedVectorType(ssz.UintType(16), 16);
pub const vec_uint16_31 = ssz.FixedVectorType(ssz.UintType(16), 31);
pub const vec_uint16_512 = ssz.FixedVectorType(ssz.UintType(16), 512);
pub const vec_uint16_513 = ssz.FixedVectorType(ssz.UintType(16), 513);
pub const vec_uint32_0 = ssz.FixedVectorType(ssz.UintType(32), 0);
pub const vec_uint32_1 = ssz.FixedVectorType(ssz.UintType(32), 1);
pub const vec_uint32_2 = ssz.FixedVectorType(ssz.UintType(32), 2);
pub const vec_uint32_3 = ssz.FixedVectorType(ssz.UintType(32), 3);
pub const vec_uint32_4 = ssz.FixedVectorType(ssz.UintType(32), 4);
pub const vec_uint32_5 = ssz.FixedVectorType(ssz.UintType(32), 5);
pub const vec_uint32_8 = ssz.FixedVectorType(ssz.UintType(32), 8);
pub const vec_uint32_16 = ssz.FixedVectorType(ssz.UintType(32), 16);
pub const vec_uint32_31 = ssz.FixedVectorType(ssz.UintType(32), 31);
pub const vec_uint32_512 = ssz.FixedVectorType(ssz.UintType(32), 512);
pub const vec_uint32_513 = ssz.FixedVectorType(ssz.UintType(32), 513);
pub const vec_uint64_0 = ssz.FixedVectorType(ssz.UintType(64), 0);
pub const vec_uint64_1 = ssz.FixedVectorType(ssz.UintType(64), 1);
pub const vec_uint64_2 = ssz.FixedVectorType(ssz.UintType(64), 2);
pub const vec_uint64_3 = ssz.FixedVectorType(ssz.UintType(64), 3);
pub const vec_uint64_4 = ssz.FixedVectorType(ssz.UintType(64), 4);
pub const vec_uint64_5 = ssz.FixedVectorType(ssz.UintType(64), 5);
pub const vec_uint64_8 = ssz.FixedVectorType(ssz.UintType(64), 8);
pub const vec_uint64_16 = ssz.FixedVectorType(ssz.UintType(64), 16);
pub const vec_uint64_31 = ssz.FixedVectorType(ssz.UintType(64), 31);
pub const vec_uint64_512 = ssz.FixedVectorType(ssz.UintType(64), 512);
pub const vec_uint64_513 = ssz.FixedVectorType(ssz.UintType(64), 513);
pub const vec_uint128_0 = ssz.FixedVectorType(ssz.UintType(128), 0);
pub const vec_uint128_1 = ssz.FixedVectorType(ssz.UintType(128), 1);
pub const vec_uint128_2 = ssz.FixedVectorType(ssz.UintType(128), 2);
pub const vec_uint128_3 = ssz.FixedVectorType(ssz.UintType(128), 3);
pub const vec_uint128_4 = ssz.FixedVectorType(ssz.UintType(128), 4);
pub const vec_uint128_5 = ssz.FixedVectorType(ssz.UintType(128), 5);
pub const vec_uint128_8 = ssz.FixedVectorType(ssz.UintType(128), 8);
pub const vec_uint128_16 = ssz.FixedVectorType(ssz.UintType(128), 16);
pub const vec_uint128_31 = ssz.FixedVectorType(ssz.UintType(128), 31);
pub const vec_uint128_512 = ssz.FixedVectorType(ssz.UintType(128), 512);
pub const vec_uint128_513 = ssz.FixedVectorType(ssz.UintType(128), 513);
pub const vec_uint256_0 = ssz.FixedVectorType(ssz.UintType(256), 0);
pub const vec_uint256_1 = ssz.FixedVectorType(ssz.UintType(256), 1);
pub const vec_uint256_2 = ssz.FixedVectorType(ssz.UintType(256), 2);
pub const vec_uint256_3 = ssz.FixedVectorType(ssz.UintType(256), 3);
pub const vec_uint256_4 = ssz.FixedVectorType(ssz.UintType(256), 4);
pub const vec_uint256_5 = ssz.FixedVectorType(ssz.UintType(256), 5);
pub const vec_uint256_8 = ssz.FixedVectorType(ssz.UintType(256), 8);
pub const vec_uint256_16 = ssz.FixedVectorType(ssz.UintType(256), 16);
pub const vec_uint256_31 = ssz.FixedVectorType(ssz.UintType(256), 31);
pub const vec_uint256_512 = ssz.FixedVectorType(ssz.UintType(256), 512);
pub const vec_uint256_513 = ssz.FixedVectorType(ssz.UintType(256), 513);

// bitlist
pub const bitlist_1 = ssz.BitListType(1);
pub const bitlist_2 = ssz.BitListType(2);
pub const bitlist_3 = ssz.BitListType(3);
pub const bitlist_4 = ssz.BitListType(4);
pub const bitlist_5 = ssz.BitListType(5);
pub const bitlist_6 = ssz.BitListType(6);
pub const bitlist_7 = ssz.BitListType(7);
pub const bitlist_9 = ssz.BitListType(9);
pub const bitlist_15 = ssz.BitListType(15);
pub const bitlist_17 = ssz.BitListType(17);
pub const bitlist_8 = ssz.BitListType(8);
pub const bitlist_16 = ssz.BitListType(16);
pub const bitlist_31 = ssz.BitListType(31);
pub const bitlist_32 = ssz.BitListType(32);
pub const bitlist_33 = ssz.BitListType(33);
pub const bitlist_511 = ssz.BitListType(511);
pub const bitlist_512 = ssz.BitListType(512);
pub const bitlist_513 = ssz.BitListType(513);
pub const bitlist_no = ssz.BitListType(513);

// bitvector
pub const bitvec_0 = ssz.BitVectorType(1);
pub const bitvec_1 = ssz.BitVectorType(1);
pub const bitvec_2 = ssz.BitVectorType(2);
pub const bitvec_3 = ssz.BitVectorType(3);
pub const bitvec_4 = ssz.BitVectorType(4);
pub const bitvec_5 = ssz.BitVectorType(5);
pub const bitvec_6 = ssz.BitVectorType(6);
pub const bitvec_7 = ssz.BitVectorType(7);
pub const bitvec_8 = ssz.BitVectorType(8);
pub const bitvec_9 = ssz.BitVectorType(9);
pub const bitvec_15 = ssz.BitVectorType(15);
pub const bitvec_16 = ssz.BitVectorType(16);
pub const bitvec_17 = ssz.BitVectorType(17);
pub const bitvec_31 = ssz.BitVectorType(31);
pub const bitvec_32 = ssz.BitVectorType(32);
pub const bitvec_33 = ssz.BitVectorType(33);
pub const bitvec_511 = ssz.BitVectorType(511);
pub const bitvec_512 = ssz.BitVectorType(512);
pub const bitvec_513 = ssz.BitVectorType(513);

// boolean
pub const boolean = ssz.BoolType();

// containers
pub const SingleFieldTestStruct = ssz.FixedContainerType(struct {
    A: ssz.UintType(8),
});
pub const SmallTestStruct = ssz.FixedContainerType(struct {
    A: ssz.UintType(16),
    B: ssz.UintType(16),
});
pub const FixedTestStruct = ssz.FixedContainerType(struct {
    A: ssz.UintType(8),
    B: ssz.UintType(64),
    C: ssz.UintType(32),
});
pub const VarTestStruct = ssz.VariableContainerType(struct {
    A: ssz.UintType(16),
    B: ssz.FixedListType(ssz.UintType(16), 1024),
    C: ssz.UintType(8),
});
pub const ComplexTestStruct = ssz.VariableContainerType(struct {
    A: ssz.UintType(16),
    B: ssz.FixedListType(ssz.UintType(16), 128),
    C: ssz.UintType(8),
    D: ssz.ByteListType(256),
    E: VarTestStruct,
    F: ssz.FixedVectorType(FixedTestStruct, 4),
    G: ssz.VariableVectorType(VarTestStruct, 2),
});
pub const BitsStruct = ssz.VariableContainerType(struct {
    A: ssz.BitListType(5),
    B: ssz.BitVectorType(2),
    C: ssz.BitVectorType(1),
    D: ssz.BitListType(6),
    E: ssz.BitVectorType(8),
});

// Progressive container types
pub const ProgressiveTestStruct = ssz.VariableContainerType(struct {
    A: ssz.FixedProgressiveListType(ssz.UintType(8), 1048576),
    B: ssz.FixedProgressiveListType(ssz.UintType(64), 1048576),
    C: ssz.FixedProgressiveListType(SmallTestStruct, 1048576),
    D: ssz.VariableProgressiveListType(ssz.VariableProgressiveListType(VarTestStruct, 1048576), 1048576),
});

pub const ProgressiveBitsStruct = ssz.VariableContainerType(struct {
    A: ssz.BitVectorType(256),          // BitArray[256]
    B: ssz.BitListType(256),             // BitList[256]
    C: ssz.ProgressiveBitListType(8192), // BitSeq
    D: ssz.BitVectorType(257),           // BitArray[257]
    E: ssz.BitListType(257),             // BitList[257]
    F: ssz.ProgressiveBitListType(8192), // BitSeq
    G: ssz.BitVectorType(1280),          // BitArray[1280]
    H: ssz.BitListType(1280),            // BitList[1280]
    I: ssz.ProgressiveBitListType(8192), // BitSeq
    J: ssz.BitVectorType(1281),          // BitArray[1281]
    K: ssz.BitListType(1281),            // BitList[1281]
    L: ssz.ProgressiveBitListType(8192), // BitSeq
});

pub const ProgressiveSingleFieldContainerTestStruct = ssz.FixedProgressiveContainerType(struct {
    A: ssz.UintType(8),
}, &[_]u1{1});

pub const ProgressiveSingleListContainerTestStruct = ssz.VariableProgressiveContainerType(struct {
    C: ssz.ProgressiveBitListType(8192),
}, &[_]u1{ 0, 0, 0, 0, 1 });

pub const ProgressiveVarTestStruct = ssz.VariableProgressiveContainerType(struct {
    A: ssz.UintType(8),
    B: ssz.FixedListType(ssz.UintType(16), 123),
    C: ssz.ProgressiveBitListType(8192),
}, &[_]u1{ 1, 0, 1, 0, 1 });

pub const ProgressiveComplexTestStruct = ssz.VariableProgressiveContainerType(struct {
    A: ssz.UintType(8),
    B: ssz.FixedListType(ssz.UintType(16), 123),
    C: ssz.ProgressiveBitListType(8192),
    D: ssz.FixedProgressiveListType(ssz.UintType(64), 1048576),
    E: ssz.FixedProgressiveListType(SmallTestStruct, 1048576),
    F: ssz.VariableProgressiveListType(ssz.VariableProgressiveListType(VarTestStruct, 1048576), 1048576),
    G: ssz.FixedListType(ProgressiveSingleFieldContainerTestStruct, 10),
    H: ssz.VariableProgressiveListType(ProgressiveVarTestStruct, 1048576),
}, &[_]u1{ 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1 });

// uints
pub const uint_8 = ssz.UintType(8);
pub const uint_16 = ssz.UintType(16);
pub const uint_32 = ssz.UintType(32);
pub const uint_64 = ssz.UintType(64);
pub const uint_128 = ssz.UintType(128);
pub const uint_256 = ssz.UintType(256);

// basic progressive lists - using direct UintType calls for exact element sizes

pub const proglist_bool_0 = ssz.FixedProgressiveListType(ssz.BoolType(), 0);
pub const proglist_bool_1 = ssz.FixedProgressiveListType(ssz.BoolType(), 1);
pub const proglist_bool_1365 = ssz.FixedProgressiveListType(ssz.BoolType(), 1365);
pub const proglist_bool_1366 = ssz.FixedProgressiveListType(ssz.BoolType(), 1366);
pub const proglist_bool_2 = ssz.FixedProgressiveListType(ssz.BoolType(), 2);
pub const proglist_bool_20 = ssz.FixedProgressiveListType(ssz.BoolType(), 20);
pub const proglist_bool_21 = ssz.FixedProgressiveListType(ssz.BoolType(), 21);
pub const proglist_bool_22 = ssz.FixedProgressiveListType(ssz.BoolType(), 22);
pub const proglist_bool_3 = ssz.FixedProgressiveListType(ssz.BoolType(), 3);
pub const proglist_bool_341 = ssz.FixedProgressiveListType(ssz.BoolType(), 341);
pub const proglist_bool_342 = ssz.FixedProgressiveListType(ssz.BoolType(), 342);
pub const proglist_bool_4 = ssz.FixedProgressiveListType(ssz.BoolType(), 4);
pub const proglist_bool_5 = ssz.FixedProgressiveListType(ssz.BoolType(), 5);
pub const proglist_bool_8 = ssz.FixedProgressiveListType(ssz.BoolType(), 8);
pub const proglist_bool_85 = ssz.FixedProgressiveListType(ssz.BoolType(), 85);
pub const proglist_bool_86 = ssz.FixedProgressiveListType(ssz.BoolType(), 86);
pub const proglist_bool_max = ssz.FixedProgressiveListType(ssz.BoolType(), 1024);
pub const proglist_bool_zero = ssz.FixedProgressiveListType(ssz.BoolType(), 1024);
pub const proglist_uint128_0 = ssz.FixedProgressiveListType(ssz.UintType(128), 0);
pub const proglist_uint128_1 = ssz.FixedProgressiveListType(ssz.UintType(128), 1);
pub const proglist_uint128_1365 = ssz.FixedProgressiveListType(ssz.UintType(128), 1365);
pub const proglist_uint128_1366 = ssz.FixedProgressiveListType(ssz.UintType(128), 1366);
pub const proglist_uint128_2 = ssz.FixedProgressiveListType(ssz.UintType(128), 2);
pub const proglist_uint128_20 = ssz.FixedProgressiveListType(ssz.UintType(128), 20);
pub const proglist_uint128_21 = ssz.FixedProgressiveListType(ssz.UintType(128), 21);
pub const proglist_uint128_22 = ssz.FixedProgressiveListType(ssz.UintType(128), 22);
pub const proglist_uint128_3 = ssz.FixedProgressiveListType(ssz.UintType(128), 3);
pub const proglist_uint128_341 = ssz.FixedProgressiveListType(ssz.UintType(128), 341);
pub const proglist_uint128_342 = ssz.FixedProgressiveListType(ssz.UintType(128), 342);
pub const proglist_uint128_4 = ssz.FixedProgressiveListType(ssz.UintType(128), 4);
pub const proglist_uint128_5 = ssz.FixedProgressiveListType(ssz.UintType(128), 5);
pub const proglist_uint128_8 = ssz.FixedProgressiveListType(ssz.UintType(128), 8);
pub const proglist_uint128_85 = ssz.FixedProgressiveListType(ssz.UintType(128), 85);
pub const proglist_uint128_86 = ssz.FixedProgressiveListType(ssz.UintType(128), 86);
pub const proglist_uint128_max = ssz.FixedProgressiveListType(ssz.UintType(128), 1024);
pub const proglist_uint128_random = ssz.FixedProgressiveListType(ssz.UintType(128), 1024);
pub const proglist_uint128_zero = ssz.FixedProgressiveListType(ssz.UintType(128), 1024);
pub const proglist_uint16_0 = ssz.FixedProgressiveListType(ssz.UintType(16), 0);
pub const proglist_uint16_1 = ssz.FixedProgressiveListType(ssz.UintType(16), 1);
pub const proglist_uint16_1365 = ssz.FixedProgressiveListType(ssz.UintType(16), 1365);
pub const proglist_uint16_1366 = ssz.FixedProgressiveListType(ssz.UintType(16), 1366);
pub const proglist_uint16_2 = ssz.FixedProgressiveListType(ssz.UintType(16), 2);
pub const proglist_uint16_20 = ssz.FixedProgressiveListType(ssz.UintType(16), 20);
pub const proglist_uint16_21 = ssz.FixedProgressiveListType(ssz.UintType(16), 21);
pub const proglist_uint16_22 = ssz.FixedProgressiveListType(ssz.UintType(16), 22);
pub const proglist_uint16_3 = ssz.FixedProgressiveListType(ssz.UintType(16), 3);
pub const proglist_uint16_341 = ssz.FixedProgressiveListType(ssz.UintType(16), 341);
pub const proglist_uint16_342 = ssz.FixedProgressiveListType(ssz.UintType(16), 342);
pub const proglist_uint16_4 = ssz.FixedProgressiveListType(ssz.UintType(16), 4);
pub const proglist_uint16_5 = ssz.FixedProgressiveListType(ssz.UintType(16), 5);
pub const proglist_uint16_8 = ssz.FixedProgressiveListType(ssz.UintType(16), 8);
pub const proglist_uint16_85 = ssz.FixedProgressiveListType(ssz.UintType(16), 85);
pub const proglist_uint16_86 = ssz.FixedProgressiveListType(ssz.UintType(16), 86);
pub const proglist_uint16_max = ssz.FixedProgressiveListType(ssz.UintType(16), 1024);
pub const proglist_uint16_random = ssz.FixedProgressiveListType(ssz.UintType(16), 1024);
pub const proglist_uint16_zero = ssz.FixedProgressiveListType(ssz.UintType(16), 1024);
pub const proglist_uint256_0 = ssz.FixedProgressiveListType(ssz.UintType(256), 0);
pub const proglist_uint256_1 = ssz.FixedProgressiveListType(ssz.UintType(256), 1);
pub const proglist_uint256_1365 = ssz.FixedProgressiveListType(ssz.UintType(256), 1365);
pub const proglist_uint256_1366 = ssz.FixedProgressiveListType(ssz.UintType(256), 1366);
pub const proglist_uint256_2 = ssz.FixedProgressiveListType(ssz.UintType(256), 2);
pub const proglist_uint256_20 = ssz.FixedProgressiveListType(ssz.UintType(256), 20);
pub const proglist_uint256_21 = ssz.FixedProgressiveListType(ssz.UintType(256), 21);
pub const proglist_uint256_22 = ssz.FixedProgressiveListType(ssz.UintType(256), 22);
pub const proglist_uint256_3 = ssz.FixedProgressiveListType(ssz.UintType(256), 3);
pub const proglist_uint256_341 = ssz.FixedProgressiveListType(ssz.UintType(256), 341);
pub const proglist_uint256_342 = ssz.FixedProgressiveListType(ssz.UintType(256), 342);
pub const proglist_uint256_4 = ssz.FixedProgressiveListType(ssz.UintType(256), 4);
pub const proglist_uint256_5 = ssz.FixedProgressiveListType(ssz.UintType(256), 5);
pub const proglist_uint256_8 = ssz.FixedProgressiveListType(ssz.UintType(256), 8);
pub const proglist_uint256_85 = ssz.FixedProgressiveListType(ssz.UintType(256), 85);
pub const proglist_uint256_86 = ssz.FixedProgressiveListType(ssz.UintType(256), 86);
pub const proglist_uint256_max = ssz.FixedProgressiveListType(ssz.UintType(256), 1024);
pub const proglist_uint256_random = ssz.FixedProgressiveListType(ssz.UintType(256), 1024);
pub const proglist_uint256_zero = ssz.FixedProgressiveListType(ssz.UintType(256), 1024);
pub const proglist_uint32_0 = ssz.FixedProgressiveListType(ssz.UintType(32), 0);
pub const proglist_uint32_1 = ssz.FixedProgressiveListType(ssz.UintType(32), 1);
pub const proglist_uint32_1365 = ssz.FixedProgressiveListType(ssz.UintType(32), 1365);
pub const proglist_uint32_1366 = ssz.FixedProgressiveListType(ssz.UintType(32), 1366);
pub const proglist_uint32_2 = ssz.FixedProgressiveListType(ssz.UintType(32), 2);
pub const proglist_uint32_20 = ssz.FixedProgressiveListType(ssz.UintType(32), 20);
pub const proglist_uint32_21 = ssz.FixedProgressiveListType(ssz.UintType(32), 21);
pub const proglist_uint32_22 = ssz.FixedProgressiveListType(ssz.UintType(32), 22);
pub const proglist_uint32_3 = ssz.FixedProgressiveListType(ssz.UintType(32), 3);
pub const proglist_uint32_341 = ssz.FixedProgressiveListType(ssz.UintType(32), 341);
pub const proglist_uint32_342 = ssz.FixedProgressiveListType(ssz.UintType(32), 342);
pub const proglist_uint32_4 = ssz.FixedProgressiveListType(ssz.UintType(32), 4);
pub const proglist_uint32_5 = ssz.FixedProgressiveListType(ssz.UintType(32), 5);
pub const proglist_uint32_8 = ssz.FixedProgressiveListType(ssz.UintType(32), 8);
pub const proglist_uint32_85 = ssz.FixedProgressiveListType(ssz.UintType(32), 85);
pub const proglist_uint32_86 = ssz.FixedProgressiveListType(ssz.UintType(32), 86);
pub const proglist_uint32_max = ssz.FixedProgressiveListType(ssz.UintType(32), 1024);
pub const proglist_uint32_random = ssz.FixedProgressiveListType(ssz.UintType(32), 1024);
pub const proglist_uint32_zero = ssz.FixedProgressiveListType(ssz.UintType(32), 1024);
pub const proglist_uint64_0 = ssz.FixedProgressiveListType(ssz.UintType(64), 0);
pub const proglist_uint64_1 = ssz.FixedProgressiveListType(ssz.UintType(64), 1);
pub const proglist_uint64_1365 = ssz.FixedProgressiveListType(ssz.UintType(64), 1365);
pub const proglist_uint64_1366 = ssz.FixedProgressiveListType(ssz.UintType(64), 1366);
pub const proglist_uint64_2 = ssz.FixedProgressiveListType(ssz.UintType(64), 2);
pub const proglist_uint64_20 = ssz.FixedProgressiveListType(ssz.UintType(64), 20);
pub const proglist_uint64_21 = ssz.FixedProgressiveListType(ssz.UintType(64), 21);
pub const proglist_uint64_22 = ssz.FixedProgressiveListType(ssz.UintType(64), 22);
pub const proglist_uint64_3 = ssz.FixedProgressiveListType(ssz.UintType(64), 3);
pub const proglist_uint64_341 = ssz.FixedProgressiveListType(ssz.UintType(64), 341);
pub const proglist_uint64_342 = ssz.FixedProgressiveListType(ssz.UintType(64), 342);
pub const proglist_uint64_4 = ssz.FixedProgressiveListType(ssz.UintType(64), 4);
pub const proglist_uint64_5 = ssz.FixedProgressiveListType(ssz.UintType(64), 5);
pub const proglist_uint64_8 = ssz.FixedProgressiveListType(ssz.UintType(64), 8);
pub const proglist_uint64_85 = ssz.FixedProgressiveListType(ssz.UintType(64), 85);
pub const proglist_uint64_86 = ssz.FixedProgressiveListType(ssz.UintType(64), 86);
pub const proglist_uint64_max = ssz.FixedProgressiveListType(ssz.UintType(64), 1024);
pub const proglist_uint64_random = ssz.FixedProgressiveListType(ssz.UintType(64), 1024);
pub const proglist_uint64_zero = ssz.FixedProgressiveListType(ssz.UintType(64), 1024);
pub const proglist_uint8_max = ssz.FixedProgressiveListType(ssz.UintType(8), 1024);
pub const proglist_uint8_random = ssz.FixedProgressiveListType(ssz.UintType(8), 1024);
pub const proglist_uint8_zero = ssz.FixedProgressiveListType(ssz.UintType(8), 1024);
pub const proglist_bool = ssz.FixedProgressiveListType(ssz.BoolType(), 1024);
pub const proglist_uint8 = ssz.FixedProgressiveListType(ssz.UintType(8), 1024);
pub const proglist_uint16 = ssz.FixedProgressiveListType(ssz.UintType(16), 1024);
pub const proglist_uint32 = ssz.FixedProgressiveListType(ssz.UintType(32), 1024);

pub const proglist_uint64 = ssz.FixedProgressiveListType(ssz.UintType(64), 1024);
pub const proglist_uint128 = ssz.FixedProgressiveListType(ssz.UintType(128), 1024);
pub const proglist_uint256 = ssz.FixedProgressiveListType(ssz.UintType(256), 1024);
// progressive_bitlist
pub const progbitlist_zero = ssz.ProgressiveBitListType(8192);
pub const progbitlist_nil = ssz.ProgressiveBitListType(8192);
pub const progbitlist_max = ssz.ProgressiveBitListType(8192);
pub const progbitlist_random = ssz.ProgressiveBitListType(8192);
pub const progbitlist_lengthy = ssz.ProgressiveBitListType(8192);
pub const progbitlist_no = ssz.ProgressiveBitListType(8192);

// compatible_union
pub const CompatibleUnionA = ssz.CompatibleUnionType(.{
    .{ 1, ProgressiveSingleFieldContainerTestStruct },
});

pub const CompatibleUnionBC = ssz.CompatibleUnionType(.{
    .{ 2, ProgressiveSingleListContainerTestStruct },
    .{ 3, ProgressiveVarTestStruct },
});

pub const CompatibleUnionABCA = ssz.CompatibleUnionType(.{
    .{ 1, ProgressiveSingleFieldContainerTestStruct },
    .{ 2, ProgressiveSingleListContainerTestStruct },
    .{ 3, ProgressiveVarTestStruct },
    .{ 4, ProgressiveSingleFieldContainerTestStruct },
});
