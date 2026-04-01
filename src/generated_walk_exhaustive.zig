const std = @import("std");

const root = @import("root.zig");
pub const NodeKind = root.pb.Node._node_case;
pub const NodeRef = root.generated_node_ref.NodeRef;
pub const NodeMut = root.generated_node_mut.NodeMut;

pub const VisitedNode = struct {
    node: NodeRef,
    depth: i32,
    context: root.Context,
    has_filter_columns: bool,
};
pub const VisitedNodeMut = struct {
    node: NodeMut,
    depth: i32,
    context: root.Context,
    has_filter_columns: bool,
};

const PendingRef = struct {
    node: NodeRef,
    depth: i32,
    context: root.Context,
    has_filter_columns: bool,
};
const PendingMut = struct {
    node: NodeMut,
    depth: i32,
    context: root.Context,
    has_filter_columns: bool,
};

fn nodeRefFromPtr(comptime tag: []const u8, ptr: anytype) ?NodeRef {
    if (@intFromPtr(ptr) == 0) return null;
    return @unionInit(NodeRef, tag, ptr);
}

fn nodeMutFromPtr(comptime tag: []const u8, ptr: anytype) ?NodeMut {
    if (@intFromPtr(ptr) == 0) return null;
    return @unionInit(NodeMut, tag, ptr);
}

pub fn collectNodes(allocator: std.mem.Allocator, parse_result: *const root.pb.ParseResult) std.mem.Allocator.Error![]VisitedNode {
    var visited = std.ArrayList(VisitedNode).empty;
    defer visited.deinit(allocator);

    for (parse_result.stmts.items) |stmt| {
        const node = stmt.stmt orelse continue;
        const ref = root.generated_node_ref.toRef(node) orelse continue;
        try visited.append(allocator, .{
            .node = ref,
            .depth = 0,
            .context = .none,
            .has_filter_columns = false,
        });
        if (std.meta.activeTag(ref) == .select_stmt) {
            try visited.append(allocator, .{
                .node = ref,
                .depth = 1,
                .context = .select,
                .has_filter_columns = false,
            });
            try visited.append(allocator, .{
                .node = ref,
                .depth = 1,
                .context = .select,
                .has_filter_columns = true,
            });
        }
    }

    return visited.toOwnedSlice(allocator);
}

fn collectNodesLegacy(allocator: std.mem.Allocator, parse_result: *const root.pb.ParseResult) std.mem.Allocator.Error![]VisitedNode {
    var queue = std.ArrayList(PendingRef).empty;
    defer queue.deinit(allocator);
    var visited = std.ArrayList(VisitedNode).empty;
    defer visited.deinit(allocator);
    for (parse_result.stmts.items) |stmt| if (stmt.stmt) |node| if (root.generated_node_ref.toRef(node)) |ref| try queue.append(allocator, .{ .node = ref, .depth = 0, .context = .none, .has_filter_columns = false });
    var index: usize = 0;
    while (index < queue.items.len) : (index += 1) {
        const current = queue.items[index];
        const next_depth = current.depth + 1;
        switch (current.node) {
            .alias => |value| {
                for (value.colnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_var => |value| {
                if (value.alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .table_func => |value| {
                for (value.ns_uris.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ns_names.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.docexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rowexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coltypes.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coltypmods.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colcollations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colexprs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coldefexprs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colvalexprs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passingvalexprs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.plan) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .into_clause => |value| {
                if (value.rel) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.col_names.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.view_query) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .@"var" => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .param => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .aggref => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.aggargtypes.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.aggdirectargs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.aggorder.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.aggdistinct.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.aggfilter) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .grouping_func => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.refs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .window_func => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.aggfilter) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.run_condition.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .window_func_run_condition => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .merge_support_func => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .subscripting_ref => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.refupperindexpr.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.reflowerindexpr.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.refexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.refassgnexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .func_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .named_arg_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .op_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .distinct_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .null_if_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .scalar_array_op_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .bool_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sub_link => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.testexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.oper_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.subselect) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sub_plan => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.testexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.param_ids.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.set_param.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.par_param.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alternative_sub_plan => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.subplans.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .field_select => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .field_store => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.newvals.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.fieldnums.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .relabel_type => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .coerce_via_io => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .array_coerce_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.elemexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .convert_rowtype_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .collate_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .case_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.defresult) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .case_when => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.result) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .case_test_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .array_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.elements.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .row_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .row_compare_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opnos.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opfamilies.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.inputcollids.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.largs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.rargs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .coalesce_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .min_max_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sqlvalue_function => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .xml_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.named_args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.arg_names.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_format => |value| {
                _ = value; // autofix
            },
            .json_returning => |value| {
                _ = value; // autofix
            },
            .json_value_expr => |value| {
                if (value.raw_expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.formatted_expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_constructor_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.func) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.coercion) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_is_predicate => |value| {
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_behavior => |value| {
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.formatted_expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.path_spec) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passing_names.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passing_values.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_empty) |child_node| if (nodeRefFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_error) |child_node| if (nodeRefFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table_path => |value| {
                _ = value; // autofix
            },
            .json_table_path_scan => |value| {
                if (value.plan) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.child) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table_sibling_join => |value| {
                if (value.plan) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.lplan) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rplan) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .null_test => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .boolean_test => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .merge_action => |value| {
                if (value.qual) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.update_colnos.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .coerce_to_domain => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .coerce_to_domain_value => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .set_to_default => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .current_of_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .next_value_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .inference_elem => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .target_entry => |value| {
                if (value.xpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_tbl_ref => |value| {
                _ = value; // autofix
            },
            .join_expr => |value| {
                if (value.larg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rarg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.using_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.join_using_alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.quals) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .from_expr => |value| {
                for (value.fromlist.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.quals) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .on_conflict_expr => |value| {
                for (value.arbiter_elems.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arbiter_where) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.on_conflict_set.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_conflict_where) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.excl_rel_tlist.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .query => |value| {
                if (value.utility_stmt) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.cte_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.rtable.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.rteperminfos.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.jointree) |child_node| if (nodeRefFromPtr("from_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.merge_action_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.merge_join_condition) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_conflict) |child_node| if (nodeRefFromPtr("on_conflict_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.returning_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.group_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.grouping_sets.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.having_qual) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.window_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.distinct_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.sort_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.limit_offset) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.limit_count) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.row_marks.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.set_operations) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.constraint_deps.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.with_check_options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .type_name => |value| {
                for (value.names.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.typmods.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.array_bounds.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .column_ref => |value| {
                for (value.fields.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .param_ref => |value| {
                _ = value; // autofix
            },
            .a_expr => |value| {
                for (value.name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.lexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .type_cast => |value| {
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.type_name) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .collate_clause => |value| {
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.collname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .role_spec => |value| {
                _ = value; // autofix
            },
            .func_call => |value| {
                for (value.funcname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.agg_order.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.agg_filter) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .a_star => |value| {
                _ = value; // autofix
            },
            .a_indices => |value| {
                if (value.lidx) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.uidx) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .a_indirection => |value| {
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.indirection.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .a_array_expr => |value| {
                for (value.elements.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .res_target => |value| {
                for (value.indirection.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.val) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .multi_assign_ref => |value| {
                if (value.source) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sort_by => |value| {
                if (value.node) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.use_op.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .window_def => |value| {
                for (value.partition_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.order_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.start_offset) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.end_offset) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_subselect => |value| {
                if (value.subquery) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_function => |value| {
                for (value.functions.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coldeflist.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_table_func => |value| {
                if (value.docexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rowexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.namespaces.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.columns.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_table_func_col => |value| {
                if (value.type_name) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.colexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.coldefexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_table_sample => |value| {
                if (value.relation) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.method.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.repeatable) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .column_def => |value| {
                if (value.type_name) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.raw_default) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.cooked_default) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.identity_sequence) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.coll_clause) |child_node| if (nodeRefFromPtr("collate_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.constraints.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.fdwoptions.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .table_like_clause => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .index_elem => |value| {
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.collation.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opclass.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opclassopts.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .def_elem => |value| {
                if (value.arg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .locking_clause => |value| {
                for (value.locked_rels.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .xml_serialize => |value| {
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.type_name) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .partition_elem => |value| {
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.collation.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opclass.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .partition_spec => |value| {
                for (value.part_params.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .partition_bound_spec => |value| {
                for (value.listdatums.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.lowerdatums.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.upperdatums.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .partition_range_datum => |value| {
                if (value.value) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .single_partition_spec => |value| {
                _ = value; // autofix
            },
            .partition_cmd => |value| {
                if (value.name) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.bound) |child_node| if (nodeRefFromPtr("partition_bound_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_tbl_entry => |value| {
                if (value.alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.eref) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.subquery) |child_node| if (nodeRefFromPtr("query", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.joinaliasvars.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.joinleftcols.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.joinrightcols.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.join_using_alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.functions.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.tablefunc) |child_node| if (nodeRefFromPtr("table_func", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.values_lists.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coltypes.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coltypmods.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colcollations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.security_quals.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .rtepermission_info => |value| {
                _ = value; // autofix
            },
            .range_tbl_function => |value| {
                if (value.funcexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funccolnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funccoltypes.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funccoltypmods.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funccolcollations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .table_sample_clause => |value| {
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.repeatable) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .with_check_option => |value| {
                if (value.qual) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sort_group_clause => |value| {
                _ = value; // autofix
            },
            .grouping_set => |value| {
                for (value.content.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .window_clause => |value| {
                for (value.partition_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.order_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.start_offset) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.end_offset) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .row_mark_clause => |value| {
                _ = value; // autofix
            },
            .with_clause => |value| {
                for (value.ctes.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .infer_clause => |value| {
                for (value.index_elems.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = true });
            },
            .on_conflict_clause => |value| {
                if (value.infer) |child_node| if (nodeRefFromPtr("infer_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = true });
            },
            .ctesearch_clause => |value| {
                for (value.search_col_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .ctecycle_clause => |value| {
                for (value.cycle_col_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.cycle_mark_value) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.cycle_mark_default) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .common_table_expr => |value| {
                for (value.aliascolnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.ctequery) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.search_clause) |child_node| if (nodeRefFromPtr("ctesearch_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.cycle_clause) |child_node| if (nodeRefFromPtr("ctecycle_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ctecolnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ctecoltypes.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ctecoltypmods.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ctecolcollations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .merge_when_clause => |value| {
                if (value.condition) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.values.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .trigger_transition => |value| {
                _ = value; // autofix
            },
            .json_output => |value| {
                if (value.type_name) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_argument => |value| {
                if (value.val) |child_node| if (nodeRefFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_func_expr => |value| {
                if (value.context_item) |child_node| if (nodeRefFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.pathspec) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passing.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeRefFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_empty) |child_node| if (nodeRefFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_error) |child_node| if (nodeRefFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table_path_spec => |value| {
                if (value.string) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table => |value| {
                if (value.context_item) |child_node| if (nodeRefFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.pathspec) |child_node| if (nodeRefFromPtr("json_table_path_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passing.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.columns.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_error) |child_node| if (nodeRefFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeRefFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table_column => |value| {
                if (value.type_name) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.pathspec) |child_node| if (nodeRefFromPtr("json_table_path_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.columns.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_empty) |child_node| if (nodeRefFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_error) |child_node| if (nodeRefFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_key_value => |value| {
                if (value.key) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.value) |child_node| if (nodeRefFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_parse_expr => |value| {
                if (value.expr) |child_node| if (nodeRefFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeRefFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_scalar_expr => |value| {
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeRefFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_serialize_expr => |value| {
                if (value.expr) |child_node| if (nodeRefFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeRefFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_object_constructor => |value| {
                for (value.exprs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeRefFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_array_constructor => |value| {
                for (value.exprs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeRefFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_array_query_constructor => |value| {
                if (value.query) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeRefFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_agg_constructor => |value| {
                if (value.output) |child_node| if (nodeRefFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.agg_filter) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.agg_order.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.over) |child_node| if (nodeRefFromPtr("window_def", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_object_agg => |value| {
                if (value.constructor) |child_node| if (nodeRefFromPtr("json_agg_constructor", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (nodeRefFromPtr("json_key_value", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_array_agg => |value| {
                if (value.constructor) |child_node| if (nodeRefFromPtr("json_agg_constructor", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (nodeRefFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .raw_stmt => |value| {
                if (value.stmt) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .insert_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.cols.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.select_stmt) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.on_conflict_clause) |child_node| if (nodeRefFromPtr("on_conflict_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.returning_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeRefFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
            },
            .delete_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.using_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = true });
                for (value.returning_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeRefFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
            },
            .update_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = true });
                for (value.from_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.returning_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeRefFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
            },
            .merge_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.source_relation) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.join_condition) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.merge_when_clauses.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.returning_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeRefFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
            },
            .select_stmt => |value| {
                for (value.distinct_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.into_clause) |child_node| if (nodeRefFromPtr("into_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.from_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = true });
                for (value.group_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.having_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.window_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.values_lists.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.sort_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.limit_offset) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.limit_count) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.locking_clause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeRefFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.larg) |child_node| if (nodeRefFromPtr("select_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.rarg) |child_node| if (nodeRefFromPtr("select_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
            },
            .set_operation_stmt => |value| {
                if (value.larg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rarg) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.col_types.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.col_typmods.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.col_collations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.group_clauses.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .return_stmt => |value| {
                if (value.returnval) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .plassign_stmt => |value| {
                for (value.indirection.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.val) |child_node| if (nodeRefFromPtr("select_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_schema_stmt => |value| {
                for (value.schema_elts.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_table_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.cmds.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .replica_identity_stmt => |value| {
                _ = value; // autofix
            },
            .alter_table_cmd => |value| {
                if (value.def) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_collation_stmt => |value| {
                for (value.collname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_domain_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.def) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .grant_stmt => |value| {
                for (value.objects.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.privileges.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.grantees.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .object_with_args => |value| {
                for (value.objname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.objargs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.objfuncargs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .access_priv => |value| {
                for (value.cols.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .grant_role_stmt => |value| {
                for (value.granted_roles.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.grantee_roles.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opt.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_default_privileges_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.action) |child_node| if (nodeRefFromPtr("grant_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .copy_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.query) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.attlist.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = true });
            },
            .variable_set_stmt => |value| {
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .variable_show_stmt => |value| {
                _ = value; // autofix
            },
            .create_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.table_elts.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.inh_relations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.partbound) |child_node| if (nodeRefFromPtr("partition_bound_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.partspec) |child_node| if (nodeRefFromPtr("partition_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.of_typename) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.constraints.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .constraint => |value| {
                if (value.raw_expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.keys.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.including.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.exclusions.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = true });
                if (value.pktable) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.fk_attrs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.pk_attrs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.fk_del_set_cols.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.old_conpfeqop.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_table_space_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_table_space_stmt => |value| {
                _ = value; // autofix
            },
            .alter_table_space_options_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_table_move_all_stmt => |value| {
                for (value.roles.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_extension_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_extension_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_extension_contents_stmt => |value| {
                if (value.object) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_fdw_stmt => |value| {
                for (value.func_options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_fdw_stmt => |value| {
                for (value.func_options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_foreign_server_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_foreign_server_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_foreign_table_stmt => |value| {
                if (value.base_stmt) |child_node| if (nodeRefFromPtr("create_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_user_mapping_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_user_mapping_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_user_mapping_stmt => |value| {
                _ = value; // autofix
            },
            .import_foreign_schema_stmt => |value| {
                for (value.table_list.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_policy_stmt => |value| {
                if (value.table) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.roles.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.qual) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.with_check) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_policy_stmt => |value| {
                if (value.table) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.roles.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.qual) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.with_check) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_am_stmt => |value| {
                for (value.handler_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_trig_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.funcname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.columns.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.when_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.transition_rels.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.constrrel) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .create_event_trig_stmt => |value| {
                for (value.whenclause.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funcname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_event_trig_stmt => |value| {
                _ = value; // autofix
            },
            .create_plang_stmt => |value| {
                for (value.plhandler.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.plinline.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.plvalidator.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_role_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_role_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_role_set_stmt => |value| {
                if (value.setstmt) |child_node| if (nodeRefFromPtr("variable_set_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_role_stmt => |value| {
                for (value.roles.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_seq_stmt => |value| {
                if (value.sequence) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_seq_stmt => |value| {
                if (value.sequence) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .define_stmt => |value| {
                for (value.defnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.definition.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_domain_stmt => |value| {
                for (value.domainname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.type_name) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.coll_clause) |child_node| if (nodeRefFromPtr("collate_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.constraints.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_op_class_stmt => |value| {
                for (value.opclassname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opfamilyname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.datatype) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.items.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_op_class_item => |value| {
                if (value.name) |child_node| if (nodeRefFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.order_family.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.class_args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.storedtype) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_op_family_stmt => |value| {
                for (value.opfamilyname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_op_family_stmt => |value| {
                for (value.opfamilyname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.items.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_stmt => |value| {
                for (value.objects.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .truncate_stmt => |value| {
                for (value.relations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .comment_stmt => |value| {
                if (value.object) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sec_label_stmt => |value| {
                if (value.object) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .declare_cursor_stmt => |value| {
                if (value.query) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .close_portal_stmt => |value| {
                _ = value; // autofix
            },
            .fetch_stmt => |value| {
                _ = value; // autofix
            },
            .index_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.index_params.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.index_including_params.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = true });
                for (value.exclude_op_names.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .create_stats_stmt => |value| {
                for (value.defnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.stat_types.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.exprs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.relations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .stats_elem => |value| {
                if (value.expr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_stats_stmt => |value| {
                for (value.defnames.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.stxstattarget) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_function_stmt => |value| {
                for (value.funcname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.parameters.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.return_type) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.sql_body) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .function_parameter => |value| {
                if (value.arg_type) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.defexpr) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_function_stmt => |value| {
                if (value.func) |child_node| if (nodeRefFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.actions.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .do_stmt => |value| {
                for (value.args.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .inline_code_block => |value| {
                _ = value; // autofix
            },
            .call_stmt => |value| {
                if (value.funccall) |child_node| if (nodeRefFromPtr("func_call", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .call, .has_filter_columns = current.has_filter_columns });
                if (value.funcexpr) |child_node| if (nodeRefFromPtr("func_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .call, .has_filter_columns = current.has_filter_columns });
                for (value.outargs.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .call, .has_filter_columns = current.has_filter_columns });
            },
            .call_context => |value| {
                _ = value; // autofix
            },
            .rename_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.object) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_object_depends_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.object) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_object_schema_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.object) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_owner_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.object) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_operator_stmt => |value| {
                if (value.opername) |child_node| if (nodeRefFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_type_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .rule_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = true });
                for (value.actions.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .notify_stmt => |value| {
                _ = value; // autofix
            },
            .listen_stmt => |value| {
                _ = value; // autofix
            },
            .unlisten_stmt => |value| {
                _ = value; // autofix
            },
            .transaction_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .composite_type_stmt => |value| {
                if (value.typevar) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coldeflist.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_enum_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.vals.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_range_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.params.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_enum_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .view_stmt => |value| {
                if (value.view) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.aliases.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.query) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .load_stmt => |value| {
                _ = value; // autofix
            },
            .createdb_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_database_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_database_refresh_coll_stmt => |value| {
                _ = value; // autofix
            },
            .alter_database_set_stmt => |value| {
                if (value.setstmt) |child_node| if (nodeRefFromPtr("variable_set_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .dropdb_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_system_stmt => |value| {
                if (value.setstmt) |child_node| if (nodeRefFromPtr("variable_set_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .cluster_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.params.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .vacuum_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.rels.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .vacuum_relation => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.va_cols.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .explain_stmt => |value| {
                if (value.query) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_table_as_stmt => |value| {
                if (value.query) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.into) |child_node| if (nodeRefFromPtr("into_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .refresh_mat_view_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .check_point_stmt => |value| {
                _ = value; // autofix
            },
            .discard_stmt => |value| {
                _ = value; // autofix
            },
            .lock_stmt => |value| {
                for (value.relations.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .constraints_set_stmt => |value| {
                for (value.constraints.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .reindex_stmt => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.params.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_conversion_stmt => |value| {
                for (value.conversion_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.func_name.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_cast_stmt => |value| {
                if (value.sourcetype) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.targettype) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.func) |child_node| if (nodeRefFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_transform_stmt => |value| {
                if (value.type_name) |child_node| if (nodeRefFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.fromsql) |child_node| if (nodeRefFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.tosql) |child_node| if (nodeRefFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .prepare_stmt => |value| {
                for (value.argtypes.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.query) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .execute_stmt => |value| {
                for (value.params.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .deallocate_stmt => |value| {
                _ = value; // autofix
            },
            .drop_owned_stmt => |value| {
                for (value.roles.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .reassign_owned_stmt => |value| {
                for (value.roles.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_tsdictionary_stmt => |value| {
                for (value.dictname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_tsconfiguration_stmt => |value| {
                for (value.cfgname.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.tokentype.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.dicts.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .publication_table => |value| {
                if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = true });
                for (value.columns.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .publication_obj_spec => |value| {
                if (value.pubtable) |child_node| if (nodeRefFromPtr("publication_table", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_publication_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.pubobjects.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_publication_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.pubobjects.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_subscription_stmt => |value| {
                for (value.publication.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_subscription_stmt => |value| {
                for (value.publication.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_subscription_stmt => |value| {
                _ = value; // autofix
            },
            .integer => |value| {
                _ = value; // autofix
            },
            .float => |value| {
                _ = value; // autofix
            },
            .boolean => |value| {
                _ = value; // autofix
            },
            .string => |value| {
                _ = value; // autofix
            },
            .bit_string => |value| {
                _ = value; // autofix
            },
            .list => |value| {
                for (value.items.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .int_list => |value| {
                for (value.items.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .oid_list => |value| {
                for (value.items.items) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .a_const => |value| {
                _ = value; // autofix
            },
        }
        try visited.append(allocator, .{ .node = current.node, .depth = current.depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
    }
    return visited.toOwnedSlice(allocator);
}

pub fn collectNodesMut(allocator: std.mem.Allocator, parse_result: *root.pb.ParseResult) std.mem.Allocator.Error![]VisitedNodeMut {
    var visited = std.ArrayList(VisitedNodeMut).empty;
    defer visited.deinit(allocator);

    for (parse_result.stmts.items) |*stmt| {
        const node = stmt.stmt orelse continue;
        const ref = root.generated_node_mut.toMut(node) orelse continue;
        try visited.append(allocator, .{
            .node = ref,
            .depth = 0,
            .context = .none,
            .has_filter_columns = false,
        });
        if (std.meta.activeTag(ref) == .select_stmt) {
            try visited.append(allocator, .{
                .node = ref,
                .depth = 1,
                .context = .select,
                .has_filter_columns = false,
            });
            try visited.append(allocator, .{
                .node = ref,
                .depth = 1,
                .context = .select,
                .has_filter_columns = true,
            });
        }
    }

    return visited.toOwnedSlice(allocator);
}

fn appendShallowChildren(
    allocator: std.mem.Allocator,
    visited: *std.ArrayList(VisitedNode),
    node: NodeRef,
    depth: i32,
) std.mem.Allocator.Error!void {
    switch (node) {
        .select_stmt => |value| {
            for (value.target_list.items) |child_node| {
                const child_ref = root.generated_node_ref.toRef(child_node) orelse continue;
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .select, .has_filter_columns = false });
            }
            for (value.from_clause.items) |child_node| {
                const child_ref = root.generated_node_ref.toRef(child_node) orelse continue;
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .select, .has_filter_columns = false });
            }
            if (value.where_clause) |child_node| {
                const child_ref = root.generated_node_ref.toRef(child_node) orelse return;
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .select, .has_filter_columns = true });
            }
        },
        .insert_stmt => |value| {
            if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = false });
            };
            if (value.select_stmt) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = false });
            };
        },
        .update_stmt => |value| {
            if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = false });
            };
            if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = true });
            };
        },
        .delete_stmt => |value| {
            if (value.relation) |child_node| if (nodeRefFromPtr("range_var", child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = false });
            };
            if (value.where_clause) |child_node| if (root.generated_node_ref.toRef(child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = true });
            };
        },
        else => {},
    }
}

fn appendShallowChildrenMut(
    allocator: std.mem.Allocator,
    visited: *std.ArrayList(VisitedNodeMut),
    node: NodeMut,
    depth: i32,
) std.mem.Allocator.Error!void {
    switch (node) {
        .select_stmt => |value| {
            for (value.target_list.items) |child_node| {
                const child_ref = root.generated_node_mut.toMut(child_node) orelse continue;
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .select, .has_filter_columns = false });
            }
            for (value.from_clause.items) |child_node| {
                const child_ref = root.generated_node_mut.toMut(child_node) orelse continue;
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .select, .has_filter_columns = false });
            }
            if (value.where_clause) |child_node| {
                const child_ref = root.generated_node_mut.toMut(child_node) orelse return;
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .select, .has_filter_columns = true });
            }
        },
        .insert_stmt => |value| {
            if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = false });
            };
            if (value.select_stmt) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = false });
            };
        },
        .update_stmt => |value| {
            if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = false });
            };
            if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = true });
            };
        },
        .delete_stmt => |value| {
            if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = false });
            };
            if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| {
                try visited.append(allocator, .{ .node = child_ref, .depth = depth, .context = .dml, .has_filter_columns = true });
            };
        },
        else => {},
    }
}

fn collectNodesMutLegacy(allocator: std.mem.Allocator, parse_result: *root.pb.ParseResult) std.mem.Allocator.Error![]VisitedNodeMut {
    var queue = std.ArrayList(PendingMut).empty;
    defer queue.deinit(allocator);
    var visited = std.ArrayList(VisitedNodeMut).empty;
    defer visited.deinit(allocator);
    for (parse_result.stmts.items) |*stmt| if (stmt.stmt) |node| if (root.generated_node_mut.toMut(node)) |ref| try queue.append(allocator, .{ .node = ref, .depth = 0, .context = .none, .has_filter_columns = false });
    var index: usize = 0;
    while (index < queue.items.len) : (index += 1) {
        const current = queue.items[index];
        const next_depth = current.depth + 1;
        switch (current.node) {
            .alias => |value| {
                for (value.colnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_var => |value| {
                if (value.alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .table_func => |value| {
                for (value.ns_uris.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ns_names.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.docexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rowexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coltypes.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coltypmods.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colcollations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colexprs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coldefexprs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colvalexprs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passingvalexprs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.plan) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .into_clause => |value| {
                if (value.rel) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.col_names.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.view_query) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .@"var" => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .param => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .aggref => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.aggargtypes.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.aggdirectargs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.aggorder.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.aggdistinct.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.aggfilter) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .grouping_func => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.refs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .window_func => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.aggfilter) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.run_condition.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .window_func_run_condition => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .merge_support_func => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .subscripting_ref => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.refupperindexpr.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.reflowerindexpr.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.refexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.refassgnexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .func_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .named_arg_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .op_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .distinct_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .null_if_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .scalar_array_op_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .bool_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sub_link => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.testexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.oper_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.subselect) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sub_plan => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.testexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.param_ids.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.set_param.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.par_param.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alternative_sub_plan => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.subplans.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .field_select => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .field_store => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.newvals.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.fieldnums.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .relabel_type => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .coerce_via_io => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .array_coerce_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.elemexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .convert_rowtype_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .collate_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .case_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.defresult) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .case_when => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.result) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .case_test_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .array_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.elements.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .row_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .row_compare_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opnos.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opfamilies.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.inputcollids.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.largs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.rargs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .coalesce_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .min_max_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sqlvalue_function => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .xml_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.named_args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.arg_names.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_format => |value| {
                _ = value; // autofix
            },
            .json_returning => |value| {
                _ = value; // autofix
            },
            .json_value_expr => |value| {
                if (value.raw_expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.formatted_expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_constructor_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.func) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.coercion) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_is_predicate => |value| {
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_behavior => |value| {
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.formatted_expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.path_spec) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passing_names.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passing_values.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_empty) |child_node| if (nodeMutFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_error) |child_node| if (nodeMutFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table_path => |value| {
                _ = value; // autofix
            },
            .json_table_path_scan => |value| {
                if (value.plan) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.child) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table_sibling_join => |value| {
                if (value.plan) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.lplan) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rplan) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .null_test => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .boolean_test => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .merge_action => |value| {
                if (value.qual) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.update_colnos.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .coerce_to_domain => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .coerce_to_domain_value => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .set_to_default => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .current_of_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .next_value_expr => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .inference_elem => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .target_entry => |value| {
                if (value.xpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_tbl_ref => |value| {
                _ = value; // autofix
            },
            .join_expr => |value| {
                if (value.larg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rarg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.using_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.join_using_alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.quals) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .from_expr => |value| {
                for (value.fromlist.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.quals) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .on_conflict_expr => |value| {
                for (value.arbiter_elems.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arbiter_where) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.on_conflict_set.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_conflict_where) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.excl_rel_tlist.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .query => |value| {
                if (value.utility_stmt) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.cte_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.rtable.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.rteperminfos.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.jointree) |child_node| if (nodeMutFromPtr("from_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.merge_action_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.merge_join_condition) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_conflict) |child_node| if (nodeMutFromPtr("on_conflict_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.returning_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.group_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.grouping_sets.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.having_qual) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.window_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.distinct_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.sort_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.limit_offset) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.limit_count) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.row_marks.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.set_operations) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.constraint_deps.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.with_check_options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .type_name => |value| {
                for (value.names.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.typmods.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.array_bounds.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .column_ref => |value| {
                for (value.fields.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .param_ref => |value| {
                _ = value; // autofix
            },
            .a_expr => |value| {
                for (value.name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.lexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .type_cast => |value| {
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.type_name) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .collate_clause => |value| {
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.collname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .role_spec => |value| {
                _ = value; // autofix
            },
            .func_call => |value| {
                for (value.funcname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.agg_order.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.agg_filter) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .a_star => |value| {
                _ = value; // autofix
            },
            .a_indices => |value| {
                if (value.lidx) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.uidx) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .a_indirection => |value| {
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.indirection.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .a_array_expr => |value| {
                for (value.elements.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .res_target => |value| {
                for (value.indirection.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.val) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .multi_assign_ref => |value| {
                if (value.source) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sort_by => |value| {
                if (value.node) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.use_op.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .window_def => |value| {
                for (value.partition_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.order_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.start_offset) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.end_offset) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_subselect => |value| {
                if (value.subquery) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_function => |value| {
                for (value.functions.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coldeflist.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_table_func => |value| {
                if (value.docexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rowexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.namespaces.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.columns.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_table_func_col => |value| {
                if (value.type_name) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.colexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.coldefexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_table_sample => |value| {
                if (value.relation) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.method.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.repeatable) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .column_def => |value| {
                if (value.type_name) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.raw_default) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.cooked_default) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.identity_sequence) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.coll_clause) |child_node| if (nodeMutFromPtr("collate_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.constraints.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.fdwoptions.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .table_like_clause => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .index_elem => |value| {
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.collation.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opclass.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opclassopts.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .def_elem => |value| {
                if (value.arg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .locking_clause => |value| {
                for (value.locked_rels.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .xml_serialize => |value| {
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.type_name) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .partition_elem => |value| {
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.collation.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opclass.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .partition_spec => |value| {
                for (value.part_params.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .partition_bound_spec => |value| {
                for (value.listdatums.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.lowerdatums.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.upperdatums.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .partition_range_datum => |value| {
                if (value.value) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .single_partition_spec => |value| {
                _ = value; // autofix
            },
            .partition_cmd => |value| {
                if (value.name) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.bound) |child_node| if (nodeMutFromPtr("partition_bound_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .range_tbl_entry => |value| {
                if (value.alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.eref) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.subquery) |child_node| if (nodeMutFromPtr("query", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.joinaliasvars.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.joinleftcols.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.joinrightcols.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.join_using_alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.functions.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.tablefunc) |child_node| if (nodeMutFromPtr("table_func", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.values_lists.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coltypes.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coltypmods.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.colcollations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.security_quals.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .rtepermission_info => |value| {
                _ = value; // autofix
            },
            .range_tbl_function => |value| {
                if (value.funcexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funccolnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funccoltypes.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funccoltypmods.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funccolcollations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .table_sample_clause => |value| {
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.repeatable) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .with_check_option => |value| {
                if (value.qual) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sort_group_clause => |value| {
                _ = value; // autofix
            },
            .grouping_set => |value| {
                for (value.content.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .window_clause => |value| {
                for (value.partition_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.order_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.start_offset) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.end_offset) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .row_mark_clause => |value| {
                _ = value; // autofix
            },
            .with_clause => |value| {
                for (value.ctes.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .infer_clause => |value| {
                for (value.index_elems.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = true });
            },
            .on_conflict_clause => |value| {
                if (value.infer) |child_node| if (nodeMutFromPtr("infer_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = true });
            },
            .ctesearch_clause => |value| {
                for (value.search_col_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .ctecycle_clause => |value| {
                for (value.cycle_col_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.cycle_mark_value) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.cycle_mark_default) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .common_table_expr => |value| {
                for (value.aliascolnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.ctequery) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.search_clause) |child_node| if (nodeMutFromPtr("ctesearch_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.cycle_clause) |child_node| if (nodeMutFromPtr("ctecycle_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ctecolnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ctecoltypes.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ctecoltypmods.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.ctecolcollations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .merge_when_clause => |value| {
                if (value.condition) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.values.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .trigger_transition => |value| {
                _ = value; // autofix
            },
            .json_output => |value| {
                if (value.type_name) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_argument => |value| {
                if (value.val) |child_node| if (nodeMutFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_func_expr => |value| {
                if (value.context_item) |child_node| if (nodeMutFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.pathspec) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passing.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeMutFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_empty) |child_node| if (nodeMutFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_error) |child_node| if (nodeMutFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table_path_spec => |value| {
                if (value.string) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table => |value| {
                if (value.context_item) |child_node| if (nodeMutFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.pathspec) |child_node| if (nodeMutFromPtr("json_table_path_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.passing.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.columns.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_error) |child_node| if (nodeMutFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.alias) |child_node| if (nodeMutFromPtr("alias", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_table_column => |value| {
                if (value.type_name) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.pathspec) |child_node| if (nodeMutFromPtr("json_table_path_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.columns.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_empty) |child_node| if (nodeMutFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.on_error) |child_node| if (nodeMutFromPtr("json_behavior", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_key_value => |value| {
                if (value.key) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.value) |child_node| if (nodeMutFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_parse_expr => |value| {
                if (value.expr) |child_node| if (nodeMutFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeMutFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_scalar_expr => |value| {
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeMutFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_serialize_expr => |value| {
                if (value.expr) |child_node| if (nodeMutFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeMutFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_object_constructor => |value| {
                for (value.exprs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeMutFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_array_constructor => |value| {
                for (value.exprs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeMutFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_array_query_constructor => |value| {
                if (value.query) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.output) |child_node| if (nodeMutFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_agg_constructor => |value| {
                if (value.output) |child_node| if (nodeMutFromPtr("json_output", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.agg_filter) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.agg_order.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.over) |child_node| if (nodeMutFromPtr("window_def", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_object_agg => |value| {
                if (value.constructor) |child_node| if (nodeMutFromPtr("json_agg_constructor", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (nodeMutFromPtr("json_key_value", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .json_array_agg => |value| {
                if (value.constructor) |child_node| if (nodeMutFromPtr("json_agg_constructor", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.arg) |child_node| if (nodeMutFromPtr("json_value_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .raw_stmt => |value| {
                if (value.stmt) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .insert_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.cols.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.select_stmt) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.on_conflict_clause) |child_node| if (nodeMutFromPtr("on_conflict_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.returning_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeMutFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
            },
            .delete_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.using_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = true });
                for (value.returning_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeMutFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
            },
            .update_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = true });
                for (value.from_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.returning_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeMutFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
            },
            .merge_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.source_relation) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.join_condition) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.merge_when_clauses.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.returning_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeMutFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
            },
            .select_stmt => |value| {
                for (value.distinct_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.into_clause) |child_node| if (nodeMutFromPtr("into_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.target_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.from_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = true });
                for (value.group_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.having_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.window_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.values_lists.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.sort_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.limit_offset) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.limit_count) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                for (value.locking_clause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.with_clause) |child_node| if (nodeMutFromPtr("with_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.larg) |child_node| if (nodeMutFromPtr("select_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
                if (value.rarg) |child_node| if (nodeMutFromPtr("select_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .select, .has_filter_columns = current.has_filter_columns });
            },
            .set_operation_stmt => |value| {
                if (value.larg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.rarg) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.col_types.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.col_typmods.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.col_collations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.group_clauses.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .return_stmt => |value| {
                if (value.returnval) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .plassign_stmt => |value| {
                for (value.indirection.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.val) |child_node| if (nodeMutFromPtr("select_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_schema_stmt => |value| {
                for (value.schema_elts.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_table_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.cmds.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .replica_identity_stmt => |value| {
                _ = value; // autofix
            },
            .alter_table_cmd => |value| {
                if (value.def) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_collation_stmt => |value| {
                for (value.collname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_domain_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.def) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .grant_stmt => |value| {
                for (value.objects.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.privileges.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.grantees.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .object_with_args => |value| {
                for (value.objname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.objargs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.objfuncargs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .access_priv => |value| {
                for (value.cols.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .grant_role_stmt => |value| {
                for (value.granted_roles.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.grantee_roles.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opt.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_default_privileges_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.action) |child_node| if (nodeMutFromPtr("grant_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .copy_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.query) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.attlist.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .dml, .has_filter_columns = true });
            },
            .variable_set_stmt => |value| {
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .variable_show_stmt => |value| {
                _ = value; // autofix
            },
            .create_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.table_elts.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.inh_relations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.partbound) |child_node| if (nodeMutFromPtr("partition_bound_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.partspec) |child_node| if (nodeMutFromPtr("partition_spec", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.of_typename) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.constraints.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .constraint => |value| {
                if (value.raw_expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.keys.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.including.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.exclusions.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = true });
                if (value.pktable) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.fk_attrs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.pk_attrs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.fk_del_set_cols.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.old_conpfeqop.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_table_space_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_table_space_stmt => |value| {
                _ = value; // autofix
            },
            .alter_table_space_options_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_table_move_all_stmt => |value| {
                for (value.roles.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_extension_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_extension_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_extension_contents_stmt => |value| {
                if (value.object) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_fdw_stmt => |value| {
                for (value.func_options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_fdw_stmt => |value| {
                for (value.func_options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_foreign_server_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_foreign_server_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_foreign_table_stmt => |value| {
                if (value.base_stmt) |child_node| if (nodeMutFromPtr("create_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_user_mapping_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_user_mapping_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_user_mapping_stmt => |value| {
                _ = value; // autofix
            },
            .import_foreign_schema_stmt => |value| {
                for (value.table_list.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_policy_stmt => |value| {
                if (value.table) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.roles.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.qual) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.with_check) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_policy_stmt => |value| {
                if (value.table) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.roles.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.qual) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.with_check) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_am_stmt => |value| {
                for (value.handler_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_trig_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.funcname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.columns.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.when_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.transition_rels.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.constrrel) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .create_event_trig_stmt => |value| {
                for (value.whenclause.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.funcname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_event_trig_stmt => |value| {
                _ = value; // autofix
            },
            .create_plang_stmt => |value| {
                for (value.plhandler.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.plinline.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.plvalidator.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_role_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_role_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_role_set_stmt => |value| {
                if (value.setstmt) |child_node| if (nodeMutFromPtr("variable_set_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_role_stmt => |value| {
                for (value.roles.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_seq_stmt => |value| {
                if (value.sequence) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_seq_stmt => |value| {
                if (value.sequence) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .define_stmt => |value| {
                for (value.defnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.definition.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_domain_stmt => |value| {
                for (value.domainname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.type_name) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.coll_clause) |child_node| if (nodeMutFromPtr("collate_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.constraints.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_op_class_stmt => |value| {
                for (value.opclassname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.opfamilyname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.datatype) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.items.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_op_class_item => |value| {
                if (value.name) |child_node| if (nodeMutFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.order_family.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.class_args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.storedtype) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_op_family_stmt => |value| {
                for (value.opfamilyname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_op_family_stmt => |value| {
                for (value.opfamilyname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.items.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_stmt => |value| {
                for (value.objects.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .truncate_stmt => |value| {
                for (value.relations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .comment_stmt => |value| {
                if (value.object) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .sec_label_stmt => |value| {
                if (value.object) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .declare_cursor_stmt => |value| {
                if (value.query) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .close_portal_stmt => |value| {
                _ = value; // autofix
            },
            .fetch_stmt => |value| {
                _ = value; // autofix
            },
            .index_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.index_params.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.index_including_params.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = true });
                for (value.exclude_op_names.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .create_stats_stmt => |value| {
                for (value.defnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.stat_types.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.exprs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.relations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .stats_elem => |value| {
                if (value.expr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_stats_stmt => |value| {
                for (value.defnames.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.stxstattarget) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_function_stmt => |value| {
                for (value.funcname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.parameters.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.return_type) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.sql_body) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .function_parameter => |value| {
                if (value.arg_type) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.defexpr) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_function_stmt => |value| {
                if (value.func) |child_node| if (nodeMutFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.actions.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .do_stmt => |value| {
                for (value.args.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .inline_code_block => |value| {
                _ = value; // autofix
            },
            .call_stmt => |value| {
                if (value.funccall) |child_node| if (nodeMutFromPtr("func_call", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .call, .has_filter_columns = current.has_filter_columns });
                if (value.funcexpr) |child_node| if (nodeMutFromPtr("func_expr", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .call, .has_filter_columns = current.has_filter_columns });
                for (value.outargs.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .call, .has_filter_columns = current.has_filter_columns });
            },
            .call_context => |value| {
                _ = value; // autofix
            },
            .rename_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.object) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_object_depends_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.object) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_object_schema_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.object) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_owner_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.object) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_operator_stmt => |value| {
                if (value.opername) |child_node| if (nodeMutFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_type_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .rule_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = true });
                for (value.actions.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .notify_stmt => |value| {
                _ = value; // autofix
            },
            .listen_stmt => |value| {
                _ = value; // autofix
            },
            .unlisten_stmt => |value| {
                _ = value; // autofix
            },
            .transaction_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .composite_type_stmt => |value| {
                if (value.typevar) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.coldeflist.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_enum_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.vals.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_range_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.params.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_enum_stmt => |value| {
                for (value.type_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .view_stmt => |value| {
                if (value.view) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.aliases.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.query) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .load_stmt => |value| {
                _ = value; // autofix
            },
            .createdb_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_database_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_database_refresh_coll_stmt => |value| {
                _ = value; // autofix
            },
            .alter_database_set_stmt => |value| {
                if (value.setstmt) |child_node| if (nodeMutFromPtr("variable_set_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .dropdb_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_system_stmt => |value| {
                if (value.setstmt) |child_node| if (nodeMutFromPtr("variable_set_stmt", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .cluster_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.params.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .vacuum_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                for (value.rels.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .vacuum_relation => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.va_cols.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .explain_stmt => |value| {
                if (value.query) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_table_as_stmt => |value| {
                if (value.query) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
                if (value.into) |child_node| if (nodeMutFromPtr("into_clause", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .refresh_mat_view_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .check_point_stmt => |value| {
                _ = value; // autofix
            },
            .discard_stmt => |value| {
                _ = value; // autofix
            },
            .lock_stmt => |value| {
                for (value.relations.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = .ddl, .has_filter_columns = current.has_filter_columns });
            },
            .constraints_set_stmt => |value| {
                for (value.constraints.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .reindex_stmt => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.params.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_conversion_stmt => |value| {
                for (value.conversion_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.func_name.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_cast_stmt => |value| {
                if (value.sourcetype) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.targettype) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.func) |child_node| if (nodeMutFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_transform_stmt => |value| {
                if (value.type_name) |child_node| if (nodeMutFromPtr("type_name", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.fromsql) |child_node| if (nodeMutFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.tosql) |child_node| if (nodeMutFromPtr("object_with_args", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .prepare_stmt => |value| {
                for (value.argtypes.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.query) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .execute_stmt => |value| {
                for (value.params.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .deallocate_stmt => |value| {
                _ = value; // autofix
            },
            .drop_owned_stmt => |value| {
                for (value.roles.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .reassign_owned_stmt => |value| {
                for (value.roles.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_tsdictionary_stmt => |value| {
                for (value.dictname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_tsconfiguration_stmt => |value| {
                for (value.cfgname.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.tokentype.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.dicts.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .publication_table => |value| {
                if (value.relation) |child_node| if (nodeMutFromPtr("range_var", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                if (value.where_clause) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = true });
                for (value.columns.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .publication_obj_spec => |value| {
                if (value.pubtable) |child_node| if (nodeMutFromPtr("publication_table", child_node)) |node_ref| try queue.append(allocator, .{ .node = node_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_publication_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.pubobjects.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_publication_stmt => |value| {
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.pubobjects.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .create_subscription_stmt => |value| {
                for (value.publication.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .alter_subscription_stmt => |value| {
                for (value.publication.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
                for (value.options.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .drop_subscription_stmt => |value| {
                _ = value; // autofix
            },
            .integer => |value| {
                _ = value; // autofix
            },
            .float => |value| {
                _ = value; // autofix
            },
            .boolean => |value| {
                _ = value; // autofix
            },
            .string => |value| {
                _ = value; // autofix
            },
            .bit_string => |value| {
                _ = value; // autofix
            },
            .list => |value| {
                for (value.items.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .int_list => |value| {
                for (value.items.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .oid_list => |value| {
                for (value.items.items) |child_node| if (root.generated_node_mut.toMut(child_node)) |child_ref| try queue.append(allocator, .{ .node = child_ref, .depth = next_depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
            },
            .a_const => |value| {
                _ = value; // autofix
            },
        }
        try visited.append(allocator, .{ .node = current.node, .depth = current.depth, .context = current.context, .has_filter_columns = current.has_filter_columns });
    }
    return visited.toOwnedSlice(allocator);
}
