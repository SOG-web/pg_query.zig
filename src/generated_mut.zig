const std = @import("std");

const root = @import("root.zig");
pub const NodeKind = root.pb.Node._node_case;

pub const NodeMut = struct {
    kind: NodeKind,
    ptr: *anyopaque,

    pub fn cast(self: NodeMut, comptime T: type) *T {
        return @ptrCast(@alignCast(self.ptr));
    }

    pub fn toOwnedNode(self: NodeMut) ?root.pb.Node {
        return root.generated_node_mut.toRef(.{ .kind = self.kind, .ptr = self.ptr }).toOwnedNode();
    }

    pub fn deparse(self: NodeMut, allocator: root.Allocator) root.ApiError!root.Outcome(root.OwnedString) {
        return root.generated_node_mut.toRef(.{ .kind = self.kind, .ptr = self.ptr }).deparse(allocator);
    }

    pub fn deparseDirect(self: NodeMut, allocator: root.Allocator) root.ApiError!root.Outcome(root.OwnedString) {
        return root.generated_node_mut.toRef(.{ .kind = self.kind, .ptr = self.ptr }).deparseDirect(allocator);
    }
};

pub const VisitedNodeMut = struct {
    node: NodeMut,
    depth: i32,
    context: root.Context,
};

const PendingNodeMut = struct {
    node: NodeMut,
    depth: i32,
    context: root.Context,
};

pub fn collectNodesMut(allocator: std.mem.Allocator, parse_result: *root.pb.ParseResult) std.mem.Allocator.Error![]VisitedNodeMut {
    var queue = std.ArrayList(PendingNodeMut).empty;
    defer queue.deinit(allocator);

    var visited = std.ArrayList(VisitedNodeMut).empty;
    defer visited.deinit(allocator);

    for (parse_result.stmts.items) |*stmt| {
        if (stmt.stmt) |node| {
            if (toMut(node)) |ref| {
                try queue.append(allocator, .{
                    .node = ref,
                    .depth = 0,
                    .context = .none,
                });
            }
        }
    }

    var index: usize = 0;
    while (index < queue.items.len) : (index += 1) {
        const current = queue.items[index];
        try visited.append(allocator, .{
            .node = current.node,
            .depth = current.depth,
            .context = current.context,
        });
        try enqueueChildren(allocator, &queue, current);
    }

    return visited.toOwnedSlice(allocator);
}

pub fn toMut(node: *root.pb.Node) ?NodeMut {
    const tagged = node.node orelse return null;
    return .{
        .kind = std.meta.activeTag(tagged),
        .ptr = switch (node.node.?) {
            inline else => |*payload| @ptrCast(payload),
        },
    };
}

fn enqueueChildren(
    allocator: std.mem.Allocator,
    queue: *std.ArrayList(PendingNodeMut),
    current: PendingNodeMut,
) std.mem.Allocator.Error!void {
    inline for (@typeInfo(root.pb.Node.node_union).@"union".fields) |field| {
        if (@field(NodeKind, field.name) == current.node.kind) {
            const payload = current.node.cast(field.type);
            try walkStruct(
                allocator,
                queue,
                field.type,
                payload,
                current.depth + 1,
                current.context,
                current.node.kind,
            );
            return;
        }
    }
}

fn walkStruct(
    allocator: std.mem.Allocator,
    queue: *std.ArrayList(PendingNodeMut),
    comptime T: type,
    value: *T,
    depth: i32,
    context: root.Context,
    parent_kind: NodeKind,
) std.mem.Allocator.Error!void {
    inline for (@typeInfo(T).@"struct".fields) |field| {
        try walkValue(
            allocator,
            queue,
            field.type,
            &@field(value.*, field.name),
            depth,
            deriveContext(parent_kind, context),
        );
    }
}

fn walkValue(
    allocator: std.mem.Allocator,
    queue: *std.ArrayList(PendingNodeMut),
    comptime T: type,
    value: *T,
    depth: i32,
    context: root.Context,
) std.mem.Allocator.Error!void {
    if (T == root.pb.Node) {
        if (toMut(value)) |ref| {
            try queue.append(allocator, .{
                .node = ref,
                .depth = depth,
                .context = context,
            });
        }
        return;
    }

    if (nodeKindForType(T)) |kind| {
        try queue.append(allocator, .{
            .node = .{ .kind = kind, .ptr = @ptrCast(value) },
            .depth = depth,
            .context = context,
        });
        return;
    }

    switch (@typeInfo(T)) {
        .optional => |optional| {
            switch (@typeInfo(optional.child)) {
                .pointer => |pointer| if (value.*) |child| {
                    if (pointer.size != .one) return;
                    if (@intFromPtr(child) == 0) return;

                    if (pointer.child == root.pb.Node) {
                        if (toMut(child)) |ref| {
                            try queue.append(allocator, .{
                                .node = ref,
                                .depth = depth,
                                .context = context,
                            });
                        }
                        return;
                    }

                    if (nodeKindForType(pointer.child)) |kind| {
                        try queue.append(allocator, .{
                            .node = .{ .kind = kind, .ptr = @ptrCast(child) },
                            .depth = depth,
                            .context = context,
                        });
                        return;
                    }

                    if (@typeInfo(pointer.child) == .@"struct") {
                        try walkValue(
                            allocator,
                            queue,
                            pointer.child,
                            child,
                            depth,
                            context,
                        );
                    }
                },
                else => if (value.*) |*child| {
                    try walkValue(
                        allocator,
                        queue,
                        optional.child,
                        child,
                        depth,
                        context,
                    );
                },
            }
        },
        .pointer => |pointer| {
            if (pointer.size != .one) return;
            if (@intFromPtr(value.*) == 0) return;

            if (pointer.child == root.pb.Node) {
                if (toMut(value.*)) |ref| {
                    try queue.append(allocator, .{
                        .node = ref,
                        .depth = depth,
                        .context = context,
                    });
                }
                return;
            }

            if (nodeKindForType(pointer.child)) |kind| {
                try queue.append(allocator, .{
                    .node = .{ .kind = kind, .ptr = @ptrCast(value.*) },
                    .depth = depth,
                    .context = context,
                });
                return;
            }

            if (@typeInfo(pointer.child) == .@"struct") {
                try walkValue(
                    allocator,
                    queue,
                    pointer.child,
                    value.*,
                    depth,
                    context,
                );
            }
        },
        .@"struct" => {
            if (comptime isArrayListLike(T)) {
                const Elem = std.meta.Elem(@FieldType(T, "items"));
                for (value.items) |*item| {
                    try walkValue(
                        allocator,
                        queue,
                        Elem,
                        item,
                        depth,
                        context,
                    );
                }
                return;
            }

            inline for (@typeInfo(T).@"struct".fields) |field| {
                try walkValue(
                    allocator,
                    queue,
                    field.type,
                    &@field(value.*, field.name),
                    depth,
                    context,
                );
            }
        },
        else => {},
    }
}

fn deriveContext(parent_kind: NodeKind, current: root.Context) root.Context {
    return switch (parent_kind) {
        .select_stmt, .set_operation_stmt => .select,
        .insert_stmt, .update_stmt, .delete_stmt, .merge_stmt, .copy_stmt, .on_conflict_clause => .dml,
        .call_stmt => .call,
        .create_stmt, .create_schema_stmt, .create_foreign_table_stmt, .create_function_stmt, .create_role_stmt, .create_table_as_stmt, .create_trig_stmt, .create_seq_stmt, .create_domain_stmt, .create_extension_stmt, .create_policy_stmt, .create_am_stmt, .create_publication_stmt, .create_subscription_stmt, .create_stats_stmt, .create_enum_stmt, .create_range_stmt, .create_op_class_stmt, .create_op_family_stmt, .create_foreign_server_stmt, .create_fdw_stmt, .create_user_mapping_stmt, .create_table_space_stmt, .create_event_trig_stmt, .create_plang_stmt, .alter_table_stmt, .alter_table_cmd, .alter_database_stmt, .alter_database_set_stmt, .alter_database_refresh_coll_stmt, .alter_domain_stmt, .alter_collation_stmt, .alter_default_privileges_stmt, .alter_extension_stmt, .alter_extension_contents_stmt, .alter_fdw_stmt, .alter_foreign_server_stmt, .alter_function_stmt, .alter_object_depends_stmt, .alter_object_schema_stmt, .alter_owner_stmt, .alter_operator_stmt, .alter_policy_stmt, .alter_role_stmt, .alter_role_set_stmt, .alter_seq_stmt, .alter_stats_stmt, .alter_subscription_stmt, .alter_system_stmt, .alter_type_stmt, .alter_enum_stmt, .drop_stmt, .drop_role_stmt, .dropdb_stmt, .drop_subscription_stmt, .drop_table_space_stmt, .drop_user_mapping_stmt, .truncate_stmt, .view_stmt, .index_stmt, .rule_stmt, .vacuum_stmt, .cluster_stmt, .refresh_mat_view_stmt, .grant_stmt, .grant_role_stmt, .lock_stmt, .comment_stmt, .sec_label_stmt, .rename_stmt, .reindex_stmt, .replica_identity_stmt => .ddl,
        else => current,
    };
}

fn isArrayListLike(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct") return false;
    if (!@hasField(T, "items") or !@hasField(T, "capacity")) return false;
    return switch (@typeInfo(@FieldType(T, "items"))) {
        .pointer => |pointer| pointer.size == .slice,
        else => false,
    };
}

fn nodeKindForType(comptime T: type) ?NodeKind {
    inline for (@typeInfo(root.pb.Node.node_union).@"union".fields) |field| {
        if (field.type == T) return @field(NodeKind, field.name);
    }
    return null;
}
