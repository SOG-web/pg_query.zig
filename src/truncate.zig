const std = @import("std");

const generated_mut = @import("generated_mut.zig");
const root = @import("root.zig");

const Attr = enum {
    target_list,
    where_clause,
    values_lists,
    cte_query,
    cols,
};

const Possible = struct {
    attr: Attr,
    node: generated_mut.NodeMut,
    depth: i32,
    length: usize,
};

pub fn truncateGenerated(
    allocator: root.Allocator,
    parse_result: *const root.pb.ParseResult,
    max_length: usize,
) root.ApiError!root.Outcome(root.OwnedString) {
    var previous_len: usize = 0;
    var initial = try root.ops.deparseGeneratedParseResult(allocator, parse_result);
    switch (initial) {
        .err => return initial,
        .ok => |value| {
            if (value.value.len <= max_length) return initial;
            previous_len = value.value.len;
            initial.deinit();
        },
    }

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var cloned = cloneParseResult(a, parse_result) catch |err| return .{ .err = .{
        .allocator = allocator,
        .kind = .deparse,
        .message = try std.fmt.allocPrint(allocator, "failed to clone parse tree: {s}", .{@errorName(err)}),
        .funcname = null,
        .filename = null,
        .lineno = 0,
        .cursorpos = 0,
        .context = null,
    } };

    while (true) {
        const truncations = try collectTruncations(a, &cloned, a);
        if (truncations.len == 0) {
            return hardTruncateGenerated(allocator, &cloned, max_length);
        }

        std.mem.sort(Possible, truncations, {}, lessThan);
        applyTruncation(a, truncations[0]) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
        };

        const output = try root.ops.deparseGeneratedParseResult(allocator, &cloned);
        switch (output) {
            .err => return output,
            .ok => |value| {
                var owned = value;
                const normalized = try normalizeEllipsis(allocator, owned.value);
                owned.deinit();
                if (normalized.len >= previous_len) {
                    allocator.free(normalized);
                    return hardTruncateGenerated(allocator, &cloned, max_length);
                }
                previous_len = normalized.len;
                if (normalized.len <= max_length) {
                    return .{ .ok = .{ .allocator = allocator, .value = normalized } };
                }
                allocator.free(normalized);
            },
        }
    }
}

fn lessThan(_: void, a: Possible, b: Possible) bool {
    if (a.depth != b.depth) return a.depth > b.depth;
    return a.length > b.length;
}

fn collectTruncations(
    allocator: std.mem.Allocator,
    parse_result: *root.pb.ParseResult,
    scratch_allocator: root.Allocator,
) (std.mem.Allocator.Error || root.ApiError)![]Possible {
    const nodes = try generated_mut.collectNodesMut(allocator, parse_result);
    var truncations = std.ArrayList(Possible).empty;
    errdefer truncations.deinit(allocator);

    for (nodes) |visited| {
        switch (visited.node.kind) {
            .select_stmt => {
                const stmt = visited.node.cast(root.pb.SelectStmt);
                if (stmt.target_list.items.len > 0) try truncations.append(allocator, .{
                    .attr = .target_list,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try selectTargetListLength(scratch_allocator, stmt.target_list.items),
                });
                if (stmt.where_clause != null) try truncations.append(allocator, .{
                    .attr = .where_clause,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try whereClauseLength(scratch_allocator, stmt.where_clause.?),
                });
                if (stmt.values_lists.items.len > 0) try truncations.append(allocator, .{
                    .attr = .values_lists,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try selectValuesListsLength(scratch_allocator, stmt.values_lists.items),
                });
            },
            .update_stmt => {
                const stmt = visited.node.cast(root.pb.UpdateStmt);
                if (stmt.target_list.items.len > 0) try truncations.append(allocator, .{
                    .attr = .target_list,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try updateTargetListLength(scratch_allocator, stmt.target_list.items),
                });
                if (stmt.where_clause != null) try truncations.append(allocator, .{
                    .attr = .where_clause,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try whereClauseLength(scratch_allocator, stmt.where_clause.?),
                });
            },
            .delete_stmt, .copy_stmt, .index_stmt, .rule_stmt, .infer_clause => {
                const where_node = switch (visited.node.kind) {
                    .delete_stmt => visited.node.cast(root.pb.DeleteStmt).where_clause,
                    .copy_stmt => visited.node.cast(root.pb.CopyStmt).where_clause,
                    .index_stmt => visited.node.cast(root.pb.IndexStmt).where_clause,
                    .rule_stmt => visited.node.cast(root.pb.RuleStmt).where_clause,
                    .infer_clause => visited.node.cast(root.pb.InferClause).where_clause,
                    else => unreachable,
                };
                if (where_node != null) try truncations.append(allocator, .{
                    .attr = .where_clause,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try whereClauseLength(scratch_allocator, where_node.?),
                });
            },
            .insert_stmt => {
                const stmt = visited.node.cast(root.pb.InsertStmt);
                if (stmt.cols.items.len > 0) try truncations.append(allocator, .{
                    .attr = .cols,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try colsLength(scratch_allocator, stmt.cols.items),
                });
            },
            .common_table_expr => {
                const stmt = visited.node.cast(root.pb.CommonTableExpr);
                if (stmt.ctequery) |ctequery| try truncations.append(allocator, .{
                    .attr = .cte_query,
                    .node = visited.node,
                    .depth = visited.depth + 1,
                    .length = try nodeLength(scratch_allocator, ctequery),
                });
            },
            .on_conflict_clause => {
                const stmt = visited.node.cast(root.pb.OnConflictClause);
                if (stmt.target_list.items.len > 0) try truncations.append(allocator, .{
                    .attr = .target_list,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try updateTargetListLength(scratch_allocator, stmt.target_list.items),
                });
                if (stmt.where_clause != null) try truncations.append(allocator, .{
                    .attr = .where_clause,
                    .node = visited.node,
                    .depth = visited.depth,
                    .length = try whereClauseLength(scratch_allocator, stmt.where_clause.?),
                });
            },
            else => {},
        }
    }

    return truncations.toOwnedSlice(allocator);
}

fn applyTruncation(allocator: std.mem.Allocator, truncation: Possible) !void {
    switch (truncation.node.kind) {
        .select_stmt => {
            const stmt = truncation.node.cast(root.pb.SelectStmt);
            switch (truncation.attr) {
                .target_list => try replaceListWithDummyTarget(allocator, &stmt.target_list),
                .where_clause => stmt.where_clause = try dummyColumnNode(allocator),
                .values_lists => try replaceListWithDummyList(allocator, &stmt.values_lists),
                else => unreachable,
            }
        },
        .update_stmt => {
            const stmt = truncation.node.cast(root.pb.UpdateStmt);
            switch (truncation.attr) {
                .target_list => try replaceListWithDummyTarget(allocator, &stmt.target_list),
                .where_clause => stmt.where_clause = try dummyColumnNode(allocator),
                else => unreachable,
            }
        },
        .delete_stmt => truncation.node.cast(root.pb.DeleteStmt).where_clause = try dummyColumnNode(allocator),
        .copy_stmt => truncation.node.cast(root.pb.CopyStmt).where_clause = try dummyColumnNode(allocator),
        .insert_stmt => try replaceListWithDummyTarget(allocator, &truncation.node.cast(root.pb.InsertStmt).cols),
        .index_stmt => truncation.node.cast(root.pb.IndexStmt).where_clause = try dummyColumnNode(allocator),
        .rule_stmt => truncation.node.cast(root.pb.RuleStmt).where_clause = try dummyColumnNode(allocator),
        .common_table_expr => truncation.node.cast(root.pb.CommonTableExpr).ctequery = try dummyWhereSelectNode(allocator),
        .infer_clause => truncation.node.cast(root.pb.InferClause).where_clause = try dummyColumnNode(allocator),
        .on_conflict_clause => {
            const stmt = truncation.node.cast(root.pb.OnConflictClause);
            switch (truncation.attr) {
                .target_list => try replaceListWithDummyTarget(allocator, &stmt.target_list),
                .where_clause => stmt.where_clause = try dummyColumnNode(allocator),
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

fn nodeLength(allocator: root.Allocator, node: *const root.pb.Node) root.ApiError!usize {
    const node_ref = root.generated_node_ref.toRef(node) orelse return 0;
    var result = try node_ref.deparse(allocator);
    defer result.deinit();
    return switch (result) {
        .ok => |value| value.value.len,
        .err => 0,
    };
}

fn replaceListWithDummyTarget(allocator: std.mem.Allocator, list: *std.ArrayList(*root.pb.Node)) !void {
    list.clearRetainingCapacity();
    try list.append(allocator, try dummyTargetNode(allocator));
}

fn replaceListWithDummyList(allocator: std.mem.Allocator, list: *std.ArrayList(*root.pb.Node)) !void {
    list.clearRetainingCapacity();
    const inner = try allocator.create(root.pb.List);
    inner.* = .{};
    try inner.items.append(allocator, try dummyColumnNode(allocator));

    const node = try allocator.create(root.pb.Node);
    node.* = .{ .node = .{ .list = inner.* } };
    try list.append(allocator, node);
}

fn dummyTargetNode(allocator: std.mem.Allocator) !*root.pb.Node {
    const target = try allocator.create(root.pb.ResTarget);
    target.* = .{
        .name = try allocator.dupe(u8, "..."),
        .val = try dummyColumnNode(allocator),
    };
    const node = try allocator.create(root.pb.Node);
    node.* = .{ .node = .{ .res_target = target.* } };
    return node;
}

fn dummyColumnNode(allocator: std.mem.Allocator) !*root.pb.Node {
    const string_value = try allocator.create(root.pb.String);
    string_value.* = .{ .sval = try allocator.dupe(u8, "...") };

    const string_node = try allocator.create(root.pb.Node);
    string_node.* = .{ .node = .{ .string = string_value.* } };

    const column = try allocator.create(root.pb.ColumnRef);
    column.* = .{};
    try column.fields.append(allocator, string_node);

    const node = try allocator.create(root.pb.Node);
    node.* = .{ .node = .{ .column_ref = column.* } };
    return node;
}

fn dummyWhereSelectNode(allocator: std.mem.Allocator) !*root.pb.Node {
    const select = try allocator.create(root.pb.SelectStmt);
    select.* = .{};
    select.where_clause = try dummyColumnNode(allocator);
    const node = try allocator.create(root.pb.Node);
    node.* = .{ .node = .{ .select_stmt = select.* } };
    return node;
}

fn selectTargetListLength(allocator: root.Allocator, nodes: []const *root.pb.Node) root.ApiError!usize {
    const dummy = try dummySelectNode(allocator, nodes, null, &.{});
    return measuredFragmentLength(allocator, dummy, 7);
}

fn selectValuesListsLength(allocator: root.Allocator, nodes: []const *root.pb.Node) root.ApiError!usize {
    const dummy = try dummySelectNode(allocator, &.{}, null, nodes);
    return measuredFragmentLength(allocator, dummy, 7);
}

fn updateTargetListLength(allocator: root.Allocator, nodes: []const *root.pb.Node) root.ApiError!usize {
    const dummy = try dummyUpdateNode(allocator, nodes);
    return measuredFragmentLength(allocator, dummy, 13);
}

fn whereClauseLength(allocator: root.Allocator, node: *const root.pb.Node) root.ApiError!usize {
    const dummy = try dummySelectNode(allocator, &.{}, node, &.{});
    return measuredFragmentLength(allocator, dummy, 13);
}

fn colsLength(allocator: root.Allocator, nodes: []const *root.pb.Node) root.ApiError!usize {
    const dummy = try dummyInsertNode(allocator, nodes);
    return measuredFragmentLength(allocator, dummy, 31);
}

fn measuredFragmentLength(allocator: root.Allocator, node: *root.pb.Node, prefix_len: usize) root.ApiError!usize {
    const len = try nodeLength(allocator, node);
    return len -| prefix_len;
}

fn dummySelectNode(
    allocator: std.mem.Allocator,
    target_list: []const *root.pb.Node,
    where_clause: ?*const root.pb.Node,
    values_lists: []const *root.pb.Node,
) !*root.pb.Node {
    const select = try allocator.create(root.pb.SelectStmt);
    select.* = .{};
    try select.target_list.appendSlice(allocator, target_list);
    if (where_clause) |node| select.where_clause = @constCast(node);
    try select.values_lists.appendSlice(allocator, values_lists);
    select.limit_option = .LIMIT_OPTION_DEFAULT;
    select.op = .SETOP_NONE;

    const node = try allocator.create(root.pb.Node);
    node.* = .{ .node = .{ .select_stmt = select.* } };
    return node;
}

fn dummyInsertNode(allocator: std.mem.Allocator, cols: []const *root.pb.Node) !*root.pb.Node {
    const relation = try allocator.create(root.pb.RangeVar);
    relation.* = .{
        .relname = try allocator.dupe(u8, "x"),
        .inh = true,
        .relpersistence = try allocator.dupe(u8, "p"),
    };

    const insert = try allocator.create(root.pb.InsertStmt);
    insert.* = .{
        .relation = relation,
        .override = .OVERRIDING_NOT_SET,
    };
    try insert.cols.appendSlice(allocator, cols);

    const node = try allocator.create(root.pb.Node);
    node.* = .{ .node = .{ .insert_stmt = insert.* } };
    return node;
}

fn dummyUpdateNode(allocator: std.mem.Allocator, target_list: []const *root.pb.Node) !*root.pb.Node {
    const relation = try allocator.create(root.pb.RangeVar);
    relation.* = .{
        .relname = try allocator.dupe(u8, "x"),
        .inh = true,
        .relpersistence = try allocator.dupe(u8, "p"),
    };

    const update = try allocator.create(root.pb.UpdateStmt);
    update.* = .{
        .relation = relation,
    };
    try update.target_list.appendSlice(allocator, target_list);

    const node = try allocator.create(root.pb.Node);
    node.* = .{ .node = .{ .update_stmt = update.* } };
    return node;
}

fn cloneParseResult(allocator: std.mem.Allocator, parse_result: *const root.pb.ParseResult) !root.pb.ParseResult {
    var writer: std.Io.Writer.Allocating = .init(allocator);
    defer writer.deinit();

    try parse_result.encode(&writer.writer, allocator);
    var reader: std.Io.Reader = .fixed(writer.written());
    return try root.pb.ParseResult.decode(&reader, allocator);
}

fn normalizeEllipsis(allocator: root.Allocator, input: []const u8) ![]u8 {
    var output = try allocator.dupe(u8, input);
    errdefer allocator.free(output);

    output = try replaceOwned(allocator, output, "SELECT WHERE \"...\"", "...");
    output = try replaceOwned(allocator, output, "\"...\"", "...");
    output = try replaceOwned(allocator, output, "SELECT ... AS ...", "SELECT ...");
    return output;
}

fn hardTruncateGenerated(
    allocator: root.Allocator,
    parse_result: *const root.pb.ParseResult,
    max_length: usize,
) root.ApiError!root.Outcome(root.OwnedString) {
    const output = try root.ops.deparseGeneratedParseResult(allocator, parse_result);
    switch (output) {
        .err => return output,
        .ok => |value| {
            var owned = value;
            if (owned.value.len <= max_length) return .{ .ok = owned };
            const truncated = try truncateString(allocator, owned.value, max_length);
            owned.deinit();
            return .{ .ok = .{ .allocator = allocator, .value = truncated } };
        },
    }
}

fn truncateString(allocator: root.Allocator, input: []const u8, max_length: usize) ![]u8 {
    if (input.len <= max_length) return allocator.dupe(u8, input);
    if (max_length <= 3) return allocator.dupe(u8, input[0..max_length]);

    var chars: usize = 0;
    var index: usize = 0;
    const limit = max_length - 3;
    while (index < input.len and chars < limit) {
        const len = std.unicode.utf8ByteSequenceLength(input[index]) catch 1;
        if (index + len > input.len) break;
        index += len;
        chars += 1;
    }

    return std.mem.concat(allocator, u8, &.{ input[0..index], "..." });
}

fn replaceOwned(allocator: root.Allocator, input: []u8, from: []const u8, to: []const u8) ![]u8 {
    const replaced = try std.mem.replaceOwned(u8, allocator, input, from, to);
    allocator.free(input);
    return replaced;
}
