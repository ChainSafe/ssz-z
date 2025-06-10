const std = @import("std");
const Depth = @import("hashing").Depth;
const Node = @import("persistent_merkle_tree").Node;
const Gindex = @import("persistent_merkle_tree").Gindex;
const isBasicType = @import("type_kind.zig").isBasicType;

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

        pub const Data = struct {
            root: Node.Id,

            /// cached nodes for faster access of already-visited children
            children_nodes: std.AutoHashMap(Gindex, Node.Id),

            /// cached data for faster access of already-visited children
            children_data: std.AutoHashMap(Gindex, Data),

            /// whether the corresponding child node/data has changed since the last update of the root
            changed: std.AutoArrayHashMap(Gindex, void),

            pub fn init(allocator: std.mem.Allocator, pool: *Node.Pool, root: Node.Id) Data {
                try pool.ref(root);
                return Data{
                    .root = root,
                    .children_nodes = std.AutoHashMap(Gindex, Node.Id).init(allocator),
                    .children_data = std.AutoHashMap(Gindex, Data).init(allocator),
                    .changed = std.AutoArrayHashMap(Gindex, void).init(allocator),
                };
            }

            pub fn deinit(self: *Data, pool: *Node.Pool) void {
                pool.unref(self.root);
                self.children_nodes.deinit();
                self.children_data.deinit();
                self.changed.deinit();
            }

            pub fn commit(self: *Data, allocator: std.mem.Allocator, pool: *Node.Pool) !void {
                const nodes = try self.allocator.alloc(Node.Id, self.data.changed.count());
                defer self.allocator.free(nodes);

                const gindices = self.data.changed.keys();
                Gindex.sortAsc(gindices);

                for (gindices, 0..) |gindex, i| {
                    if (self.data.children_data.get(gindex)) |child_data| {
                        try child_data.commit(allocator);
                        nodes[i] = child_data.root;
                    } else if (self.data.children_nodes.get(gindex)) |child_node| {
                        nodes[i] = child_node;
                    } else {
                        return error.ChildNotFound;
                    }
                }

                const new_root = try self.data.root.setNodes(self.pool, gindices, nodes);
                try pool.ref(new_root);
                pool.unref(self.root);
                self.root = new_root;

                self.changed.clearRetainingCapacity();
            }
        };

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, pool: *Node.Pool, root: Node.Id) !Self {
            switch (ST.kind) {}
            return Self{
                .allocator = allocator,
                .pool = pool,
                .data = Data.init(allocator, pool, root),
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
            const child_data = try Data.init(self.allocator, child_node);
            gop.value_ptr.* = child_data;
            return child_data;
        }

        pub const Element: type = if (isBasicType(ST.Element))
            ST.Element.Type
        else
            TreeView(ST.Element);

        pub fn getElement(self: *Self, index: usize) Element {
            if (ST.kind != .vector and ST.kind != .list) {
                @compileError("getElement can only be used with vector or list types");
            }
            const child_gindex = Gindex.fromDepth(ST.chunk_depth, index);
            if (comptime isBasicType(ST.Element)) {
                var value: ST.Element.Type = undefined;
                const child_node = try self.getChildNode(child_gindex);
                try ST.Element.tree.toValue(child_node, self.pool, &value);
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

        pub fn setElement(self: *Self, index: usize, value: Element) !void {
            if (ST.kind != .vector and ST.kind != .list) {
                @compileError("setElement can only be used with vector or list types");
            }
            const child_gindex = Gindex.fromDepth(ST.chunk_depth, index);
            try self.data.changed.put(child_gindex, void);
            if (comptime isBasicType(ST.Element)) {
                const child_node = try self.getChildNode(child_gindex);
                try self.data.children_nodes.put(
                    child_gindex,
                    try ST.Element.tree.fromValuePacked(
                        child_node,
                        self.pool,
                        index,
                        &value,
                    ),
                );
            } else {
                try self.data.children_data.put(
                    child_gindex,
                    value.data,
                );
            }
        }

        pub fn Field(comptime field_name: []const u8) type {
            const ChildST = @field(ST.fields, field_name).type;
            if (comptime isBasicType(ChildST)) {
                return ChildST.Type;
            } else {
                return TreeView(ChildST);
            }
        }

        pub fn getField(self: *Self, comptime field_name: []const u8) Field(ST, field_name) {
            if (comptime ST.kind != .container) {
                @compileError("getField can only be used with container types");
            }
            const field_index = ST.getFieldIndex(field_name);
            const ChildST = @field(ST.fields, field_name).type;
            const child_gindex = Gindex.fromDepth(ST.chunk_depth, field_index);
            if (comptime isBasicType(ChildST)) {
                var value: ChildST.Type = undefined;
                const child_node = try self.getChildNode(child_gindex);
                try ChildST.tree.toValue(child_node, self.pool, &value);
                return value;
            } else {
                const child_data = try self.getChildData(child_gindex);

                // TODO only update changed if the subview is mutable
                self.data.changed.put(child_gindex, void);

                return TreeView(ChildST){
                    .allocator = self.allocator,
                    .pool = self.pool,
                    .data = child_data,
                };
            }
        }

        pub fn setField(self: *Self, comptime field_name: []const u8, value: Field(ST, field_name)) !void {
            if (comptime ST.kind != .container) {
                @compileError("setField can only be used with container types");
            }
            const field_index = ST.getFieldIndex(field_name);
            const ChildST = @field(ST.fields, field_name).type;
            const child_gindex = Gindex.fromDepth(ST.chunk_depth, field_index);
            try self.data.changed.put(child_gindex, void);
            if (comptime isBasicType(ChildST)) {
                try self.data.children_nodes.put(
                    child_gindex,
                    try ChildST.tree.fromValue(
                        self.pool,
                        &value,
                    ),
                );
            } else {
                try self.data.children_data.put(
                    child_gindex,
                    value.data,
                );
            }
        }
    };
}
