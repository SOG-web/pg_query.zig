const std = @import("std");

const root = @import("root.zig");

pub const RouteDecision = enum {
    replica,
    primary,
    reject,
    unknown,
};

pub const StatementCategory = enum {
    read,
    write,
    transaction_control,
    session_control,
    prepare,
    execute,
    copy,
    ddl,
    unknown,
};

pub const RouteReason = enum {
    read_only,
    contains_write_stmt,
    contains_locking_read,
    contains_transaction_control,
    contains_session_mutation,
    contains_prepare_execute,
    contains_temp_object_access,
    contains_unknown_stmt,
    contains_copy_from,
    contains_ddl,
    explain_analyze,
    empty_batch,
};

pub const AnalysisFlags = struct {
    contains_multi_stmt: bool = false,
    contains_locking_read: bool = false,
    contains_temp_object_access: bool = false,
    contains_session_mutation: bool = false,
    contains_prepare_execute: bool = false,
    begins_transaction: bool = false,
    ends_transaction: bool = false,
    changes_session_state: bool = false,
    requires_same_backend: bool = false,
    invalidates_replica_routing: bool = false,

    pub fn deinit(self: *AnalysisFlags) void {
        self.* = undefined;
    }
};

pub const BatchAnalysis = struct {
    allocator: root.Allocator,
    decision: RouteDecision,
    category: StatementCategory,
    requires_primary_reason: RouteReason,
    statement_count: usize,
    statement_categories: []StatementCategory,
    flags: AnalysisFlags,
    safe_on_replica: bool,

    // Compatibility aliases for older call sites.
    has_locking_read: bool,
    has_write_stmt: bool,
    has_transaction_control: bool,
    has_session_control: bool,
    has_unknown_stmt: bool,

    pub fn deinit(self: *BatchAnalysis) void {
        self.allocator.free(self.statement_categories);
        self.* = undefined;
    }

    pub fn clone(self: *const BatchAnalysis, allocator: root.Allocator) root.Allocator.Error!BatchAnalysis {
        return .{
            .allocator = allocator,
            .decision = self.decision,
            .category = self.category,
            .requires_primary_reason = self.requires_primary_reason,
            .statement_count = self.statement_count,
            .statement_categories = try allocator.dupe(StatementCategory, self.statement_categories),
            .flags = self.flags,
            .safe_on_replica = self.safe_on_replica,
            .has_locking_read = self.has_locking_read,
            .has_write_stmt = self.has_write_stmt,
            .has_transaction_control = self.has_transaction_control,
            .has_session_control = self.has_session_control,
            .has_unknown_stmt = self.has_unknown_stmt,
        };
    }

    pub fn safeOnReplica(self: *const BatchAnalysis) bool {
        return self.safe_on_replica;
    }
};

pub const Decision = RouteDecision;
pub const Category = StatementCategory;
pub const Analysis = BatchAnalysis;

const StatementAnalysis = struct {
    category: StatementCategory,
    requires_primary_reason: ?RouteReason = null,
};

pub fn analyzeSql(allocator: root.Allocator, sql: []const u8) root.ApiError!root.Outcome(BatchAnalysis) {
    var parsed = try root.ops.parseViaRawToGenerated(allocator, sql);
    defer parsed.deinit();

    switch (parsed) {
        .err => |err| return .{ .err = err },
        .ok => |value| return .{ .ok = try analyzeParseResult(allocator, &value.protobuf) },
    }
}

pub fn analyzeParseResult(
    allocator: root.Allocator,
    parse_result: *const root.pb.ParseResult,
) root.Allocator.Error!BatchAnalysis {
    const stmt_count = parse_result.stmts.items.len;
    const statement_categories = try allocator.alloc(StatementCategory, stmt_count);
    errdefer allocator.free(statement_categories);

    var analysis: BatchAnalysis = .{
        .allocator = allocator,
        .decision = .unknown,
        .category = .unknown,
        .requires_primary_reason = .empty_batch,
        .statement_count = stmt_count,
        .statement_categories = statement_categories,
        .flags = .{
            .contains_multi_stmt = stmt_count > 1,
        },
        .safe_on_replica = false,
        .has_locking_read = false,
        .has_write_stmt = false,
        .has_transaction_control = false,
        .has_session_control = false,
        .has_unknown_stmt = false,
    };

    for (statement_categories) |*category| category.* = .unknown;

    for (0..stmt_count) |index| {
        const stmt = root.parse_result.stmtNodeTyped(parse_result, index) orelse {
            analysis.has_unknown_stmt = true;
            continue;
        };

        const stmt_analysis = classifyStmt(stmt, &analysis.flags);
        analysis.statement_categories[index] = stmt_analysis.category;
        accumulateCategory(&analysis, stmt_analysis.category);
        if (stmt_analysis.requires_primary_reason) |reason| {
            escalatePrimary(&analysis, reason);
        }
    }

    const temp_access = containsTempObjectAccess(allocator, parse_result) catch false;
    if (temp_access) {
        analysis.flags.contains_temp_object_access = true;
        analysis.flags.requires_same_backend = true;
        analysis.flags.invalidates_replica_routing = true;
        escalatePrimary(&analysis, .contains_temp_object_access);
    }

    finalizeBatch(&analysis);
    return analysis;
}

fn finalizeBatch(analysis: *BatchAnalysis) void {
    syncCompatibilityFlags(analysis);

    if (analysis.statement_count == 0) {
        analysis.decision = .unknown;
        analysis.category = .unknown;
        analysis.requires_primary_reason = .empty_batch;
        analysis.safe_on_replica = false;
        return;
    }

    if (analysis.decision == .primary or analysis.decision == .reject) {
        analysis.safe_on_replica = false;
        return;
    }

    analysis.decision = .replica;
    analysis.category = if (analysis.statement_count == 1) analysis.statement_categories[0] else .read;
    analysis.requires_primary_reason = .read_only;
    analysis.safe_on_replica = true;
}

fn syncCompatibilityFlags(analysis: *BatchAnalysis) void {
    analysis.has_locking_read = analysis.flags.contains_locking_read;
    if (analysis.flags.contains_session_mutation or analysis.flags.contains_prepare_execute) {
        analysis.has_session_control = true;
    }
}

fn accumulateCategory(analysis: *BatchAnalysis, category: StatementCategory) void {
    switch (category) {
        .write, .ddl, .copy => analysis.has_write_stmt = true,
        .transaction_control => analysis.has_transaction_control = true,
        .session_control, .prepare, .execute => analysis.has_session_control = true,
        .unknown => analysis.has_unknown_stmt = true,
        .read => {},
    }

    if (analysis.statement_count == 1 or analysis.category == .unknown) {
        analysis.category = category;
    }
}

fn escalatePrimary(analysis: *BatchAnalysis, reason: RouteReason) void {
    if (analysis.decision == .primary or analysis.decision == .reject) return;
    analysis.decision = .primary;
    analysis.requires_primary_reason = reason;
    analysis.safe_on_replica = false;
}

fn classifyStmt(node: root.generated_node_ref.NodeRef, flags: *AnalysisFlags) StatementAnalysis {
    return switch (node) {
        .select_stmt => |stmt| classifySelect(stmt, flags),
        .explain_stmt => |stmt| classifyExplain(stmt, flags),
        .copy_stmt => |stmt| classifyCopy(stmt),
        .prepare_stmt => |stmt| classifyPrepare(stmt, flags),
        .execute_stmt => classifyExecute(flags),
        .transaction_stmt => |stmt| classifyTransaction(stmt, flags),
        .declare_cursor_stmt, .close_portal_stmt, .constraints_set_stmt => classifyTransactionLike(flags),
        .variable_set_stmt, .variable_show_stmt, .discard_stmt, .notify_stmt, .listen_stmt, .unlisten_stmt, .load_stmt, .fetch_stmt, .lock_stmt, .check_point_stmt => classifySessionControl(flags),
        .insert_stmt, .update_stmt, .delete_stmt, .merge_stmt, .do_stmt, .call_stmt, .truncate_stmt, .comment_stmt, .sec_label_stmt, .grant_stmt, .grant_role_stmt, .alter_default_privileges_stmt, .cluster_stmt, .vacuum_stmt, .refresh_mat_view_stmt, .reindex_stmt => .{
            .category = .write,
            .requires_primary_reason = .contains_write_stmt,
        },
        .alter_table_stmt, .alter_table_cmd, .alter_domain_stmt, .create_stmt, .create_schema_stmt, .create_table_as_stmt, .create_seq_stmt, .alter_seq_stmt, .define_stmt, .create_domain_stmt, .create_op_class_stmt, .create_op_family_stmt, .alter_op_family_stmt, .drop_stmt, .index_stmt, .create_stats_stmt, .alter_stats_stmt, .create_function_stmt, .alter_function_stmt, .rename_stmt, .alter_object_depends_stmt, .alter_object_schema_stmt, .alter_owner_stmt, .alter_operator_stmt, .alter_type_stmt, .rule_stmt, .view_stmt, .createdb_stmt, .alter_database_stmt, .alter_database_refresh_coll_stmt, .alter_database_set_stmt, .dropdb_stmt, .alter_system_stmt, .create_conversion_stmt, .create_cast_stmt, .create_transform_stmt, .create_extension_stmt, .alter_extension_stmt, .alter_extension_contents_stmt, .create_fdw_stmt, .alter_fdw_stmt, .create_foreign_server_stmt, .alter_foreign_server_stmt, .create_foreign_table_stmt, .create_user_mapping_stmt, .alter_user_mapping_stmt, .drop_user_mapping_stmt, .import_foreign_schema_stmt, .create_policy_stmt, .alter_policy_stmt, .create_am_stmt, .create_trig_stmt, .create_event_trig_stmt, .alter_event_trig_stmt, .create_plang_stmt, .create_role_stmt, .alter_role_stmt, .alter_role_set_stmt, .drop_role_stmt, .create_publication_stmt, .alter_publication_stmt, .create_subscription_stmt, .alter_subscription_stmt, .drop_subscription_stmt, .alter_collation_stmt, .replica_identity_stmt, .composite_type_stmt, .create_enum_stmt, .create_range_stmt, .alter_enum_stmt, .alter_tsdictionary_stmt, .alter_tsconfiguration_stmt, .create_table_space_stmt, .drop_table_space_stmt, .alter_table_space_options_stmt, .alter_table_move_all_stmt => .{
            .category = .ddl,
            .requires_primary_reason = .contains_ddl,
        },
        else => .{
            .category = .unknown,
            .requires_primary_reason = .contains_unknown_stmt,
        },
    };
}

fn classifySelect(stmt: *const root.pb.SelectStmt, flags: *AnalysisFlags) StatementAnalysis {
    if (stmt.locking_clause.items.len > 0) {
        flags.contains_locking_read = true;
        return .{
            .category = .read,
            .requires_primary_reason = .contains_locking_read,
        };
    }

    if (stmt.into_clause != null) {
        return .{
            .category = .write,
            .requires_primary_reason = .contains_write_stmt,
        };
    }

    if (stmt.with_clause) |with_clause| {
        for (with_clause.ctes.items) |cte_node| {
            const cte_ref = root.generated_node_ref.toRef(cte_node) orelse continue;
            if (cte_ref != .common_table_expr) continue;
            if (cte_ref.common_table_expr.ctequery) |query_node| {
                const query_ref = root.generated_node_ref.toRef(query_node) orelse {
                    return .{ .category = .unknown, .requires_primary_reason = .contains_unknown_stmt };
                };
                const nested = classifyStmt(query_ref, flags);
                if (nested.requires_primary_reason != null) return nested;
            }
        }
    }

    if (stmt.larg) |larg| {
        const nested = classifySelect(larg, flags);
        if (nested.requires_primary_reason != null) return nested;
    }
    if (stmt.rarg) |rarg| {
        const nested = classifySelect(rarg, flags);
        if (nested.requires_primary_reason != null) return nested;
    }

    return .{ .category = .read };
}

pub const TokenClassification = enum {
    read_only,
    read_write,
    ambiguous,
};

pub fn classifySqlViaTokens(allocator: root.Allocator, sql: []const u8) root.ApiError!TokenClassification {
    var scan_result = try root.ops.scanRaw(allocator, sql);
    defer scan_result.deinit();

    return switch (scan_result) {
        .ok => |value| classifyTokens(value.tokens, sql),
        .err => error.AnalysisFailed,
    };
}

fn classifyTokens(tokens: []const root.RawScanToken, sql: []const u8) TokenClassification {
    _ = sql;
    var saw_select = false;
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const t = tokens[i].token;

        switch (t) {
            651 => saw_select = true,
            473, 726, 382, 711, 729, 525 => return .read_write,
            356, 288, 397, 440, 633 => return .read_write,
            308, 341, 636, 643 => return .read_write,
            598, 413, 373 => return .read_write,
            517 => return .read_write,
            511, 551, 723 => return .read_write,
            354 => return .read_write,
            428 => {
                if (saw_select) {
                    var j = i + 1;
                    while (j < tokens.len) : (j += 1) {
                        switch (tokens[j].token) {
                            726, 661 => return .read_write,
                            549, 483 => continue,
                            258, 745, 275, 276 => continue,
                            else => break,
                        }
                    }
                }
            },
            479 => {
                if (saw_select) return .read_write;
            },
            415 => {
                var j = i + 1;
                while (j < tokens.len) : (j += 1) {
                    switch (tokens[j].token) {
                        291 => return .read_write,
                        745, 275, 276 => continue,
                        else => break,
                    }
                }
            },
            59 => {
                saw_select = false;
            },
            else => {},
        }
    }

    if (saw_select) return .read_only;
    return .ambiguous;
}

fn classifyExplain(stmt: *const root.pb.ExplainStmt, flags: *AnalysisFlags) StatementAnalysis {
    for (stmt.options.items) |option_node| {
        const option_ref = root.generated_node_ref.toRef(option_node) orelse continue;
        if (option_ref != .def_elem) continue;
        if (std.ascii.eqlIgnoreCase(option_ref.def_elem.defname, "analyze")) {
            return .{
                .category = .write,
                .requires_primary_reason = .explain_analyze,
            };
        }
    }

    if (stmt.query) |query_node| {
        const query_ref = root.generated_node_ref.toRef(query_node) orelse {
            return .{ .category = .unknown, .requires_primary_reason = .contains_unknown_stmt };
        };
        return classifyStmt(query_ref, flags);
    }

    return .{ .category = .read };
}

fn classifyCopy(stmt: *const root.pb.CopyStmt) StatementAnalysis {
    return if (stmt.is_from)
        .{
            .category = .copy,
            .requires_primary_reason = .contains_copy_from,
        }
    else
        .{ .category = .copy, .requires_primary_reason = .contains_write_stmt };
}

fn classifyPrepare(stmt: *const root.pb.PrepareStmt, flags: *AnalysisFlags) StatementAnalysis {
    _ = stmt;
    flags.contains_prepare_execute = true;
    flags.changes_session_state = true;
    flags.requires_same_backend = true;
    flags.invalidates_replica_routing = true;
    return .{
        .category = .prepare,
        .requires_primary_reason = .contains_prepare_execute,
    };
}

fn classifyExecute(flags: *AnalysisFlags) StatementAnalysis {
    flags.contains_prepare_execute = true;
    flags.changes_session_state = true;
    flags.requires_same_backend = true;
    flags.invalidates_replica_routing = true;
    return .{
        .category = .execute,
        .requires_primary_reason = .contains_prepare_execute,
    };
}

fn classifyTransaction(stmt: *const root.pb.TransactionStmt, flags: *AnalysisFlags) StatementAnalysis {
    switch (stmt.kind) {
        .TRANS_STMT_BEGIN, .TRANS_STMT_START, .TRANS_STMT_SAVEPOINT => flags.begins_transaction = true,
        .TRANS_STMT_COMMIT, .TRANS_STMT_ROLLBACK, .TRANS_STMT_RELEASE, .TRANS_STMT_ROLLBACK_TO, .TRANS_STMT_PREPARE => flags.ends_transaction = true,
        else => {},
    }
    flags.changes_session_state = true;
    flags.requires_same_backend = true;
    flags.invalidates_replica_routing = true;
    return .{
        .category = .transaction_control,
        .requires_primary_reason = .contains_transaction_control,
    };
}

fn classifyTransactionLike(flags: *AnalysisFlags) StatementAnalysis {
    flags.changes_session_state = true;
    flags.requires_same_backend = true;
    flags.invalidates_replica_routing = true;
    return .{
        .category = .transaction_control,
        .requires_primary_reason = .contains_transaction_control,
    };
}

fn classifySessionControl(flags: *AnalysisFlags) StatementAnalysis {
    flags.contains_session_mutation = true;
    flags.changes_session_state = true;
    flags.requires_same_backend = true;
    flags.invalidates_replica_routing = true;
    return .{
        .category = .session_control,
        .requires_primary_reason = .contains_session_mutation,
    };
}

fn containsTempObjectAccess(allocator: root.Allocator, parse_result: *const root.pb.ParseResult) root.Allocator.Error!bool {
    const visited = try root.generated_walk_exhaustive.collectNodes(allocator, parse_result);
    defer allocator.free(visited);

    for (visited) |entry| {
        if (entry.node != .range_var) continue;
        const range_var = entry.node.range_var;
        if (std.mem.eql(u8, range_var.relpersistence, "t")) return true;
        if (std.ascii.eqlIgnoreCase(range_var.schemaname, "pg_temp")) return true;
        if (std.mem.startsWith(u8, range_var.relname, "pg_temp")) return true;
    }

    return false;
}

test "router routes plain select to replica" {
    const allocator = std.testing.allocator;

    var outcome = try analyzeSql(allocator, "SELECT * FROM users");
    defer outcome.deinit();

    switch (outcome) {
        .ok => |analysis| {
            try std.testing.expectEqual(RouteDecision.replica, analysis.decision);
            try std.testing.expectEqual(StatementCategory.read, analysis.category);
            try std.testing.expect(analysis.safe_on_replica);
        },
        .err => return error.UnexpectedRouterError,
    }
}

test "router routes locking select to primary" {
    const allocator = std.testing.allocator;

    var outcome = try analyzeSql(allocator, "SELECT * FROM users FOR UPDATE");
    defer outcome.deinit();

    switch (outcome) {
        .ok => |analysis| {
            try std.testing.expectEqual(RouteDecision.primary, analysis.decision);
            try std.testing.expectEqual(RouteReason.contains_locking_read, analysis.requires_primary_reason);
            try std.testing.expect(analysis.flags.contains_locking_read);
        },
        .err => return error.UnexpectedRouterError,
    }
}

test "router routes prepare to primary and marks backend affinity" {
    const allocator = std.testing.allocator;

    var outcome = try analyzeSql(allocator, "PREPARE p AS SELECT * FROM users");
    defer outcome.deinit();

    switch (outcome) {
        .ok => |analysis| {
            try std.testing.expectEqual(RouteDecision.primary, analysis.decision);
            try std.testing.expectEqual(StatementCategory.prepare, analysis.category);
            try std.testing.expect(analysis.flags.contains_prepare_execute);
            try std.testing.expect(analysis.flags.requires_same_backend);
        },
        .err => return error.UnexpectedRouterError,
    }
}

test "router routes mixed batch to primary" {
    const allocator = std.testing.allocator;

    var outcome = try analyzeSql(allocator, "SELECT 1; INSERT INTO users (id) VALUES (1)");
    defer outcome.deinit();

    switch (outcome) {
        .ok => |analysis| {
            try std.testing.expectEqual(RouteDecision.primary, analysis.decision);
            try std.testing.expectEqual(@as(usize, 2), analysis.statement_count);
            try std.testing.expect(analysis.flags.contains_multi_stmt);
            try std.testing.expectEqual(StatementCategory.read, analysis.statement_categories[0]);
            try std.testing.expectEqual(StatementCategory.write, analysis.statement_categories[1]);
        },
        .err => return error.UnexpectedRouterError,
    }
}
