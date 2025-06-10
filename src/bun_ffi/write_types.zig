const std = @import("std");
const consensus_types = @import("consensus_types");
const ssz = @import("ssz");

pub fn main() void {
    std.debug.print("{d}\n", .{max_types});

    doThings();
}

const max_types = getAllFieldCount();

const type_enum = enum {
    bool,
};

fn getFieldCount(comptime ST: type) usize {
    return switch (ST.kind) {
        .uint, .bool => 1,
        .vector, .list => {
            if (comptime ssz.isBitListType(ST) or ssz.isBitVectorType(ST) or ssz.isByteListType(ST) or ssz.isByteVectorType(ST)) {
                return 1;
            }
            return 1 + getFieldCount(ST.Element);
        },
        .container => {
            var i = 1;
            inline for (ST.fields) |field| {
                i += getFieldCount(field.type);
            }
            return i;
        },
    };
}

fn getFieldCountForFork(comptime fork: type) usize {
    var i: usize = 0;
    const decls = @typeInfo(fork).@"struct".decls;
    inline for (decls) |decl| {
        @setEvalBranchQuota(100_000);
        i += getFieldCount(@field(fork, decl.name));
    }
    return i;
}

fn getAllFieldCount() usize {
    var i: usize = 0;
    i += getFieldCountForFork(consensus_types.primitive);
    i += getFieldCountForFork(consensus_types.phase0);
    i += getFieldCountForFork(consensus_types.altair);
    i += getFieldCountForFork(consensus_types.bellatrix);
    i += getFieldCountForFork(consensus_types.capella);
    i += getFieldCountForFork(consensus_types.deneb);
    i += getFieldCountForFork(consensus_types.electra);
    return i;
}

pub fn typeId(comptime T: type) usize {
    // Capture the type so memoisation doesn't collapse
    const Marker = struct {
        var anchor: u8 = 0;
        var _ = T; // <‑‑ needed since 0.12 to keep Marker unique per T
    };
    // The address of `anchor` is distinct for each instantiation of `Marker`.
    return @intFromPtr(&Marker.anchor);
}

fn doThings() void {
    // comptime {
    //     const type_map = TypeMap.init(std.testing.allocator);
    //     _ = type_map.put(bool, 1);
    //     _ = type_map.put(u8, 2);
    //     _ = type_map.put(u16, 3);
    //     _ = type_map.put(u32, 4);
    //     _ = type_map.put(u64, 5);
    //     _ = type_map.put(u128, 6);
    //     _ = type_map.put(u256, 7);
    //     _ = type_map.put(Bytes4, 8);
    //     _ = type_map.put(Bytes8, 9);
    //     _ = type_map.put(Bytes20, 10);
    //     _ = type_map.put(Bytes32, 11);
    //     _ = type_map.put(Bytes48, 12);
    //     _ = type_map.put(Bytes96, 13);
    // }
}

fn writeType(
    comptime ST: type,
    comptime name: []const u8,
    writer: std.io.AnyWriter,
) void {
    writer.print("pub const {s} = {s};\n", {});
}

fn writeBool(
    comptime ST: type,
    comptime name: []const u8,
    writer: std.io.AnyWriter,
) void {
    writer.print("pub const {s} = {s};\n", {});
}

fn writeFixedContainer(
    comptime ST: type,
    comptime name: []const u8,
    writer: std.io.AnyWriter,
) void {
    writer.print("export const {s}_kind: u8 = {d};\n", .{
        name,
        @intFromEnum(ST.kind),
    });
    writer.print("export const {s}_fixed_size: usize = {d};\n", .{
        name,
        ST.fixed_size,
    });
    writer.print("export const {s}_field_offsets: [{d}]usize = {{{any}}};\n", .{
        name,
        ST.fields.len,
        ST.field_offsets,
    });
    writer.print("export const {s}_chunk_count: usize = {d};\n", .{
        name,
        ST.chunk_count,
    });
    writer.print("export const {s}_chunk_depth: u8 = {d};\n", .{
        name,
        ST.chunk_depth,
    });
}
