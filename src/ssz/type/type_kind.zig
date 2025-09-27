const std = @import("std");
const native_endian = @import("builtin").cpu.arch.endian();

pub const TypeKind = enum {
    uint,
    bool,
    vector,
    list,
    progressive_list,
    container,
};

/// Basic types are primitives
pub fn isBasicType(T: type) bool {
    return T.kind == .uint or T.kind == .bool;
}

// Fixed-size types have a known size
pub fn isFixedType(T: type) bool {
    return switch (T.kind) {
        .uint, .bool => true,
        .list, .progressive_list => false,
        .vector => isFixedType(T.Element),
        .container => {
            inline for (T.fields) |field| {
                if (!isFixedType(field.type)) {
                    return false;
                }
            }
            return true;
        },
    };
}

// Progressive list types
pub fn isProgressiveListType(T: type) bool {
    return T.kind == .progressive_list;
}
