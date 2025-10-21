const std = @import("std");
const Depth = @import("hashing").Depth;
const Node = @import("persistent_merkle_tree").Node;
const Gindex = @import("persistent_merkle_tree").Gindex;
const isBasicType = @import("type/type_kind.zig").isBasicType;

pub const Data = struct {
    root: Node.Id,

    /// cached nodes for faster access of already-visited children
    children_nodes: std.AutoHashMap(Gindex, Node.Id),

    /// cached data for faster access of already-visited children
    children_data: std.AutoHashMap(Gindex, Data),

    /// whether the corresponding child node/data has changed since the last update of the root
    changed: std.AutoArrayHashMap(Gindex, void),

    pub fn init(allocator: std.mem.Allocator, pool: *Node.Pool, root: Node.Id) !Data {
        try pool.ref(root);
        return Data{
            .root = root,
            .children_nodes = std.AutoHashMap(Gindex, Node.Id).init(allocator),
            .children_data = std.AutoHashMap(Gindex, Data).init(allocator),
            .changed = std.AutoArrayHashMap(Gindex, void).init(allocator),
        };
    }

    /// Deinitialize the Data and free all associated resources.
    /// This also deinits all child Data recursively.
    pub fn deinit(self: *Data, pool: *Node.Pool) void {
        pool.unref(self.root);
        self.children_nodes.deinit();
        var value_iter = self.children_data.valueIterator();
        while (value_iter.next()) |child_data| {
            child_data.deinit(pool);
        }
        self.children_data.deinit();
        self.changed.deinit();
    }

    pub fn commit(self: *Data, allocator: std.mem.Allocator, pool: *Node.Pool) !void {
        const nodes = try allocator.alloc(Node.Id, self.changed.count());
        defer allocator.free(nodes);

        const gindices = self.changed.keys();
        Gindex.sortAsc(gindices);

        for (gindices, 0..) |gindex, i| {
            if (self.children_data.getPtr(gindex)) |child_data| {
                try child_data.commit(allocator, pool);
                nodes[i] = child_data.root;
            } else if (self.children_nodes.get(gindex)) |child_node| {
                nodes[i] = child_node;
            } else {
                return error.ChildNotFound;
            }
        }

        const new_root = try self.root.setNodes(pool, gindices, nodes);
        try pool.ref(new_root);
        pool.unref(self.root);
        self.root = new_root;

        self.changed.clearRetainingCapacity();
    }
};

/// A treeview provides a view into a merkle tree of a given SSZ type.
/// It maintains and takes ownership recursively of a Data struct, which caches nodes and child Data.
pub fn TreeView(comptime ST: type) type {
    comptime {
        if (isBasicType(ST)) {
            @compileError("TreeView cannot be used with basic types");
        }
    }
    return struct {
        allocator: std.mem.Allocator,
        pool: *Node.Pool,
        data: Data,
        pub const SszType: type = ST;

        const Self = @This();

        inline fn elementsPerChunk() usize {
            return switch (ST.Element.kind) {
                .bool => 256,
                .uint => 32 / ST.Element.fixed_size,
                else => 1,
            };
        }

        // Get chunk index given element index
        // eg. bit vector index = 600 yields 2 because 600th bit is in 2nd chunk because each chunk holds 256 bits
        inline fn chunkIndex(index: usize) usize {
            if (ST.kind != .vector and ST.kind != .list) {
                @compileError("chunkIndex is only available for vector or list types");
            }
            return if (comptime isBasicType(ST.element)) index / elementsPerChunk() else index;
        }

        // Given element index, return index within the chunk
        // eg. bit vector index = 600 yields 88 because 600th bit is the 88th bit in 2nd chunk
        inline fn elementOffset(index: usize) usize {
            if (ST.kind != .vector and ST.kind != .list) {
                @compileError("elementOffset is only available for vector or list types");
            }
            return if (comptime isBasicType(ST.Element)) index % elementsPerChunk() else index;
        }

        pub fn init(allocator: std.mem.Allocator, pool: *Node.Pool, root: Node.Id) !Self {
            return Self{
                .allocator = allocator,
                .pool = pool,
                .data = try Data.init(allocator, pool, root),
            };
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit(self.pool);
        }

        pub fn commit(self: *Self) !void {
            try self.data.commit(self.allocator, self.pool);
        }

        pub fn hashTreeRoot(self: *Self, out: *[32]u8) !void {
            try self.commit();
            out.* = self.data.root.getRoot(self.pool).*;
        }

        fn getChildNode(self: *Self, gindex: Gindex) !Node.Id {
            const gop = try self.data.children_nodes.getOrPut(gindex);
            if (gop.found_existing) {
                return gop.value_ptr.*;
            }
            const child_node = try self.data.root.getNode(self.pool, gindex);
            gop.value_ptr.* = child_node;
            return child_node;
        }

        fn getChildData(self: *Self, gindex: Gindex) !Data {
            const gop = try self.data.children_data.getOrPut(gindex);
            if (gop.found_existing) {
                return gop.value_ptr.*;
            }
            const child_node = try self.getChildNode(gindex);
            const child_data = try Data.init(self.allocator, self.pool, child_node);
            gop.value_ptr.* = child_data;
            return child_data;
        }

        pub const Element: type = if (isBasicType(ST.Element))
            ST.Element.Type
        else
            TreeView(ST.Element);

        /// Get an element by index. If the element is a basic type, returns the value directly.
        /// Caller borrows a copy of the value so there is no need to deinit it.
        pub fn getElement(self: *Self, index: usize) Element {
            if (ST.kind != .vector and ST.kind != .list) {
                @compileError("getElement can only be used with vector or list types");
            }
            const child_gindex = Gindex.fromDepth(ST.chunk_depth, chunkIndex(index));
            if (comptime isBasicType(ST.Element)) {
                var value: ST.Element.Type = undefined;
                const child_node = try self.getChildNode(child_gindex);
                try ST.Element.tree.toValuePacked(child_node, self.pool, elementOffset(index), &value);
                return value;
            } else {
                const child_data = try self.getChildData(child_gindex);

                // TODO only update changed if the subview is mutable
                self.data.changed.put(child_gindex, void);

                return TreeView(ST.Element){
                    .allocator = self.allocator,
                    .pool = self.pool,
                    .data = child_data,
                };
            }
        }

        /// Set an element by index. If the element is a basic type, pass the value directly.
        /// If the element is a complex type, pass a TreeView of the corresponding type.
        /// The caller transfers ownership of the `value` TreeView to this parent view.
        /// The existing TreeView, if any, will be deinited by this function.
        pub fn setElement(self: *Self, index: usize, value: Element) !void {
            if (ST.kind != .vector and ST.kind != .list) {
                @compileError("setElement can only be used with vector or list types");
            }
            const child_gindex = Gindex.fromDepth(ST.chunk_depth, chunkIndex(index));
            try self.data.changed.put(child_gindex, void);
            if (comptime isBasicType(ST.Element)) {
                const child_node = try self.getChildNode(child_gindex);
                try self.data.children_nodes.put(
                    child_gindex,
                    try ST.Element.tree.fromValuePacked(
                        child_node,
                        self.pool,
                        elementOffset(index),
                        &value,
                    ),
                );
            } else {
                const opt_old_data = try self.data.children_data.fetchPut(
                    child_gindex,
                    value.data,
                );
                if (opt_old_data) |old_data_value| {
                    var data: *Data = @constCast(&old_data_value.value);
                    data.deinit(self.pool);
                }
            }
        }

        pub fn Field(comptime field_name: []const u8) type {
            const ChildST = ST.getFieldType(field_name);
            if (comptime isBasicType(ChildST)) {
                return ChildST.Type;
            } else {
                return TreeView(ChildST);
            }
        }

        /// Get a field by name. If the field is a basic type, returns the value directly.
        /// Caller borrows a copy of the value so there is no need to deinit it.
        pub fn getField(self: *Self, comptime field_name: []const u8) !Field(field_name) {
            if (comptime ST.kind != .container) {
                @compileError("getField can only be used with container types");
            }
            const field_index = comptime ST.getFieldIndex(field_name);
            const ChildST = ST.getFieldType(field_name);
            const child_gindex = Gindex.fromDepth(ST.chunk_depth, field_index);
            if (comptime isBasicType(ChildST)) {
                var value: ChildST.Type = undefined;
                const child_node = try self.getChildNode(child_gindex);
                try ChildST.tree.toValue(child_node, self.pool, &value);
                return value;
            } else {
                const child_data = try self.getChildData(child_gindex);

                // TODO only update changed if the subview is mutable
                try self.data.changed.put(child_gindex, {});

                return TreeView(ChildST){
                    .allocator = self.allocator,
                    .pool = self.pool,
                    .data = child_data,
                };
            }
        }

        /// Set a field by name. If the field is a basic type, pass the value directly.
        /// If the field is a complex type, pass a TreeView of the corresponding type.
        /// The caller transfers ownership of the `value` TreeView to this parent view.
        /// The existing TreeView, if any, will be deinited by this function.
        pub fn setField(self: *Self, comptime field_name: []const u8, value: Field(field_name)) !void {
            if (comptime ST.kind != .container) {
                @compileError("setField can only be used with container types");
            }
            const field_index = comptime ST.getFieldIndex(field_name);
            const ChildST = ST.getFieldType(field_name);
            const child_gindex = Gindex.fromDepth(ST.chunk_depth, field_index);
            try self.data.changed.put(child_gindex, {});
            if (comptime isBasicType(ChildST)) {
                const opt_old_node = try self.data.children_nodes.fetchPut(
                    child_gindex,
                    try ChildST.tree.fromValue(
                        self.pool,
                        &value,
                    ),
                );
                if (opt_old_node) |old_node| {
                    self.pool.unref(old_node.value);
                }
            } else {
                const opt_old_data = try self.data.children_data.fetchPut(
                    child_gindex,
                    value.data,
                );
                if (opt_old_data) |old_data_value| {
                    var data: *Data = @constCast(&old_data_value.value);
                    data.deinit(self.pool);
                }
            }
        }
    };
}
