const std = @import("std");
const hashtree = @import("hashtree");

/// Hash a slice of 32-byte arrays into a slice of 32-byte outputs.
///
/// This function will error if `in.len != 2 * out.len`.
pub const hash = hashtree.hash;

/// Hash a single pair of 32-byte arrays into a 32-byte output.
pub fn hashOne(out: *[32]u8, left: *const [32]u8, right: *const [32]u8) void {
    var in = [_][32]u8{ left.*, right.* };
    hashtree.hash(@ptrCast(out), &in) catch unreachable;
}

const max_batch_hash = 16;
/// Hash up to `max_batch_hash` pairs of 32-byte arrays into `max_batch_hash` 32-byte outputs.
pub fn hashMulti(out: []*[32]u8, ins: []*const [32]u8) !void {
    if (out.len > max_batch_hash) {
        return error.OutOverflow;
    }

    if (ins.len != 2 * out.len) {
        return error.InvalidInput;
    }

    if (out.len == 0) {
        return;
    }

    var in_buf: [max_batch_hash * 2][32]u8 = undefined;
    for (ins, 0..) |in, i| {
        in_buf[i] = in.*;
    }

    var out_buf: [max_batch_hash][32]u8 = undefined;
    try hashtree.hash(out_buf[0..out.len], in_buf[0..ins.len]);

    for (out, 0..) |item, i| {
        item.* = out_buf[i];
    }
}

test "hashOne works correctly" {
    const obj1: [32]u8 = [_]u8{1} ** 32;
    const obj2: [32]u8 = [_]u8{2} ** 32;
    var hash_result: [32]u8 = undefined;

    // Call the function and ensure it works without error
    hashOne(&hash_result, &obj1, &obj2);

    // Print the hash for manual inspection (optional)
    // std.debug.print("Hash value: {any}\n", .{hash_result});
    // std.debug.print("Hash hex: {s}\n", .{std.fmt.bytesToHex(hash_result, .lower)});
    // try std.testing.expect(mem.eql(u8, &hash_result, &expected_hash));
}

test hashOne {
    const in = [_][32]u8{[_]u8{1} ** 32} ** 4;
    var out: [2][32]u8 = undefined;
    try hash(&out, &in);
    // std.debug.print("@@@ out: {any}\n", .{out});
    var out2: [32]u8 = undefined;
    hashOne(&out2, &in[0], &in[2]);
    // std.debug.print("@@@ out2: {any}\n", .{out2});
    try std.testing.expectEqualSlices(u8, &out2, &out[0]);
    try std.testing.expectEqualSlices(u8, &out2, &out[1]);
}

test hashMulti {
    const lens = [_]usize{ 1, 2, 3, 4, 5, 6, 7, 8 };
    inline for (lens) |len| {
        const ins = [_][32]u8{
            [_]u8{1} ** 32,
            [_]u8{2} ** 32,
        } ** len;
        var in_ptrs: [len * 2]*const [32]u8 = undefined;
        inline for (0..len) |i| {
            in_ptrs[i * 2] = &ins[i * 2];
            in_ptrs[i * 2 + 1] = &ins[i * 2 + 1];
        }

        var out = [_][32]u8{
            [_]u8{0} ** 32,
        } ** len;
        var out_ptrs: [len]*[32]u8 = undefined;
        inline for (0..len) |i| {
            out_ptrs[i] = &out[i];
        }

        try hashMulti(out_ptrs[0..], in_ptrs[0..]);
        inline for (1..len) |i| {
            try std.testing.expectEqualSlices(u8, &out[0], &out[i]);
        }
    }
}

// test "hashMulti vs hashOne" {
//     const len = 16;
//     var now = std.time.nanoTimestamp();

//     const ins = [_][32]u8{
//         [_]u8{1} ** 32,
//         [_]u8{2} ** 32,
//     } ** len;
//     var in_ptrs: [len * 2]*const [32]u8 = undefined;
//     inline for (0..len) |i| {
//         in_ptrs[i * 2] = &ins[i * 2];
//         in_ptrs[i * 2 + 1] = &ins[i * 2 + 1];
//     }

//     const iterations = 1_000;
//     for (0..iterations) |_| {
//         var out = [_][32]u8{
//             [_]u8{0} ** 32,
//         } ** len;
//         var out_ptrs: [len]*[32]u8 = undefined;
//         inline for (0..len) |i| {
//             out_ptrs[i] = &out[i];
//         }

//         try hashMulti(out_ptrs[0..], in_ptrs[0..]);
//         // inline for (1..len) |i| {
//         //     try std.testing.expectEqualSlices(u8, &out[0], &out[i]);
//         // }
//     }
//     std.debug.print("hashMulti: {d} ns\n", .{std.time.nanoTimestamp() - now});

//     now = std.time.nanoTimestamp();
//     const ins_2 = [_][32]u8{
//         [_]u8{1} ** 32,
//         [_]u8{2} ** 32,
//     };
//     for (0..iterations) |_| {
//         for (0..len) |_| {
//             var out: [32]u8 = undefined;
//             hashOne(&out, &ins_2[0], &ins_2[1]);
//         }
//     }
//     std.debug.print("hashOne performance: {d} ns\n", .{std.time.nanoTimestamp() - now});
// }

test "hashTree.hash one vs multi" {
    const lens = [_]usize{ 4, 8, 16 };
    inline for (lens) |len| {
        const ins = [_][32]u8{
            [_]u8{1} ** 32,
            [_]u8{2} ** 32,
        } ** len;

        const iterations = 1_000;

        var out = [_][32]u8{
            [_]u8{0} ** 32,
        } ** len;
        var now = std.time.nanoTimestamp();
        for (0..iterations) |_| {
            try hashtree.hash(&out, &ins);
        }
        std.debug.print("hashOne.hash: batch len={d} {d} ns\n", .{ len, std.time.nanoTimestamp() - now });

        now = std.time.nanoTimestamp();
        for (0..iterations) |_| {
            for (0..len) |i| {
                try hashtree.hash(out[i .. i + 1], ins[2 * i .. 2 * i + 2]);
            }
        }
        std.debug.print("hashOne.hash: single {d} times {d} ns\n", .{ len, std.time.nanoTimestamp() - now });
    }
}
