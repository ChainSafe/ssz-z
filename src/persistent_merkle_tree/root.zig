const std = @import("std");
const testing = std.testing;

// re-export depth for convenience
pub const Depth = @import("hashing").Depth;
pub const max_depth = @import("hashing").max_depth;

pub const Gindex = @import("gindex.zig").Gindex;
pub const Node = @import("Node.zig");
pub const View = @import("View.zig");

test {
    testing.refAllDecls(@This());
}
