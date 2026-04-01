const std = @import("std");

const root = @import("root.zig");

pub fn deparse(allocator: root.Allocator, parse_result: *const root.pb.ParseResult) root.ApiError!root.Outcome(root.OwnedString) {
    return root.ops.deparseGeneratedParseResult(allocator, parse_result);
}

pub fn deparseDirect(allocator: root.Allocator, parse_result: *const root.pb.ParseResult) root.ApiError!root.Outcome(root.OwnedString) {
    return root.ops.deparseGeneratedParseResult(allocator, parse_result);
}

pub fn nodes(allocator: std.mem.Allocator, parse_result: *const root.pb.ParseResult) std.mem.Allocator.Error![]root.generated_walk_exhaustive.VisitedNode {
    return root.generated_walk_exhaustive.collectNodes(allocator, parse_result);
}

pub fn nodesMut(allocator: std.mem.Allocator, parse_result: *root.pb.ParseResult) std.mem.Allocator.Error![]root.generated_walk_exhaustive.VisitedNodeMut {
    return root.generated_walk_exhaustive.collectNodesMut(allocator, parse_result);
}

pub fn stmtNodeTyped(parse_result: *const root.pb.ParseResult, index: usize) ?root.generated_node_ref.NodeRef {
    if (index >= parse_result.stmts.items.len) return null;
    const stmt = parse_result.stmts.items[index].stmt orelse return null;
    return root.generated_node_ref.toRef(stmt);
}

pub fn stmtNodeTypedMut(parse_result: *root.pb.ParseResult, index: usize) ?root.generated_node_mut.NodeMut {
    if (index >= parse_result.stmts.items.len) return null;
    const stmt = parse_result.stmts.items[index].stmt orelse return null;
    return root.generated_node_mut.toMut(stmt);
}

pub fn truncate(
    allocator: root.Allocator,
    parse_result: *const root.pb.ParseResult,
    max_length: usize,
) root.ApiError!root.Outcome(root.OwnedString) {
    return root.truncate.truncateGenerated(allocator, parse_result, max_length);
}

pub fn statementTypes(allocator: std.mem.Allocator, parse_result: *const root.pb.ParseResult) std.mem.Allocator.Error![][]const u8 {
    var result = std.ArrayList([]const u8).empty;
    defer result.deinit(allocator);

    for (parse_result.stmts.items) |stmt| {
        const node = stmt.stmt orelse continue;
        const tagged = node.node orelse continue;
        try result.append(allocator, statementTypeName(std.meta.activeTag(tagged)));
    }

    return result.toOwnedSlice(allocator);
}

fn statementTypeName(kind: root.pb.Node._node_case) []const u8 {
    return switch (kind) {
        .insert_stmt => "InsertStmt",
        .delete_stmt => "DeleteStmt",
        .update_stmt => "UpdateStmt",
        .select_stmt => "SelectStmt",
        .merge_stmt => "MergeStmt",
        .alter_table_stmt => "AlterTableStmt",
        .alter_table_cmd => "AlterTableCmd",
        .alter_domain_stmt => "AlterDomainStmt",
        .set_operation_stmt => "SetOperationStmt",
        .grant_stmt => "GrantStmt",
        .grant_role_stmt => "GrantRoleStmt",
        .alter_default_privileges_stmt => "AlterDefaultPrivilegesStmt",
        .close_portal_stmt => "ClosePortalStmt",
        .cluster_stmt => "ClusterStmt",
        .copy_stmt => "CopyStmt",
        .create_stmt => "CreateStmt",
        .define_stmt => "DefineStmt",
        .drop_stmt => "DropStmt",
        .truncate_stmt => "TruncateStmt",
        .comment_stmt => "CommentStmt",
        .fetch_stmt => "FetchStmt",
        .index_stmt => "IndexStmt",
        .create_function_stmt => "CreateFunctionStmt",
        .alter_function_stmt => "AlterFunctionStmt",
        .do_stmt => "DoStmt",
        .rename_stmt => "RenameStmt",
        .rule_stmt => "RuleStmt",
        .notify_stmt => "NotifyStmt",
        .listen_stmt => "ListenStmt",
        .unlisten_stmt => "UnlistenStmt",
        .transaction_stmt => "TransactionStmt",
        .view_stmt => "ViewStmt",
        .load_stmt => "LoadStmt",
        .create_domain_stmt => "CreateDomainStmt",
        .createdb_stmt => "CreatedbStmt",
        .dropdb_stmt => "DropdbStmt",
        .vacuum_stmt => "VacuumStmt",
        .explain_stmt => "ExplainStmt",
        .create_table_as_stmt => "CreateTableAsStmt",
        .create_seq_stmt => "CreateSeqStmt",
        .alter_seq_stmt => "AlterSeqStmt",
        .variable_set_stmt => "VariableSetStmt",
        .variable_show_stmt => "VariableShowStmt",
        .discard_stmt => "DiscardStmt",
        .create_trig_stmt => "CreateTrigStmt",
        .create_plang_stmt => "CreatePLangStmt",
        .create_role_stmt => "CreateRoleStmt",
        .alter_role_stmt => "AlterRoleStmt",
        .drop_role_stmt => "DropRoleStmt",
        .lock_stmt => "LockStmt",
        .constraints_set_stmt => "ConstraintsSetStmt",
        .reindex_stmt => "ReindexStmt",
        .check_point_stmt => "CheckPointStmt",
        .create_schema_stmt => "CreateSchemaStmt",
        .alter_database_stmt => "AlterDatabaseStmt",
        .alter_database_set_stmt => "AlterDatabaseSetStmt",
        .alter_role_set_stmt => "AlterRoleSetStmt",
        .create_conversion_stmt => "CreateConversionStmt",
        .create_cast_stmt => "CreateCastStmt",
        .create_op_class_stmt => "CreateOpClassStmt",
        .create_op_family_stmt => "CreateOpFamilyStmt",
        .alter_op_family_stmt => "AlterOpFamilyStmt",
        .prepare_stmt => "PrepareStmt",
        .execute_stmt => "ExecuteStmt",
        .deallocate_stmt => "DeallocateStmt",
        .declare_cursor_stmt => "DeclareCursorStmt",
        .create_table_space_stmt => "CreateTableSpaceStmt",
        .drop_table_space_stmt => "DropTableSpaceStmt",
        .alter_object_depends_stmt => "AlterObjectDependsStmt",
        .alter_object_schema_stmt => "AlterObjectSchemaStmt",
        .alter_owner_stmt => "AlterOwnerStmt",
        .alter_operator_stmt => "AlterOperatorStmt",
        .alter_type_stmt => "AlterTypeStmt",
        .drop_owned_stmt => "DropOwnedStmt",
        .reassign_owned_stmt => "ReassignOwnedStmt",
        .composite_type_stmt => "CompositeTypeStmt",
        .create_enum_stmt => "CreateEnumStmt",
        .create_range_stmt => "CreateRangeStmt",
        .alter_enum_stmt => "AlterEnumStmt",
        .alter_tsdictionary_stmt => "AlterTsDictionaryStmt",
        .alter_tsconfiguration_stmt => "AlterTsConfigurationStmt",
        .create_fdw_stmt => "CreateFdwStmt",
        .alter_fdw_stmt => "AlterFdwStmt",
        .create_foreign_server_stmt => "CreateForeignServerStmt",
        .alter_foreign_server_stmt => "AlterForeignServerStmt",
        .create_user_mapping_stmt => "CreateUserMappingStmt",
        .alter_user_mapping_stmt => "AlterUserMappingStmt",
        .drop_user_mapping_stmt => "DropUserMappingStmt",
        .alter_table_space_options_stmt => "AlterTableSpaceOptionsStmt",
        .alter_table_move_all_stmt => "AlterTableMoveAllStmt",
        .sec_label_stmt => "SecLabelStmt",
        .create_foreign_table_stmt => "CreateForeignTableStmt",
        .import_foreign_schema_stmt => "ImportForeignSchemaStmt",
        .create_extension_stmt => "CreateExtensionStmt",
        .alter_extension_stmt => "AlterExtensionStmt",
        .alter_extension_contents_stmt => "AlterExtensionContentsStmt",
        .create_event_trig_stmt => "CreateEventTrigStmt",
        .alter_event_trig_stmt => "AlterEventTrigStmt",
        .refresh_mat_view_stmt => "RefreshMatViewStmt",
        .replica_identity_stmt => "ReplicaIdentityStmt",
        .alter_system_stmt => "AlterSystemStmt",
        .create_policy_stmt => "CreatePolicyStmt",
        .alter_policy_stmt => "AlterPolicyStmt",
        .create_transform_stmt => "CreateTransformStmt",
        .create_am_stmt => "CreateAmStmt",
        .create_publication_stmt => "CreatePublicationStmt",
        .alter_publication_stmt => "AlterPublicationStmt",
        .create_subscription_stmt => "CreateSubscriptionStmt",
        .alter_subscription_stmt => "AlterSubscriptionStmt",
        .drop_subscription_stmt => "DropSubscriptionStmt",
        .create_stats_stmt => "CreateStatsStmt",
        .alter_collation_stmt => "AlterCollationStmt",
        .call_stmt => "CallStmt",
        .alter_stats_stmt => "AlterStatsStmt",
        .alter_database_refresh_coll_stmt => "AlterDatabaseRefreshCollStmt",
        .return_stmt => "ReturnStmt",
        .plassign_stmt => "PlAssignStmt",
        else => @tagName(kind),
    };
}
