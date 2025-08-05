const std = @import("std");

//
// Given a byte (0 -> 255), return a Array of boolean with length = 8, little endian.
// Ex: 1 => [true false false false false false false false]
//     5 => [true false true false false fase false false]
//
pub fn computeByteToBitBooleanArray(byte: u8) ![8]bool {
    var bools: [8]bool = undefined;
    for (0..8) |i| {
        const mask = @as(u8, 1) << @intCast(i);
        bools[i] = (byte & mask) != 0;
    }
    return bools;
}
