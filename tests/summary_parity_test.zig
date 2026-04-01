const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

fn sortStrings(values: [][]const u8) void {
    std.sort.block([]const u8, values, {}, struct {
        fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.order(u8, lhs, rhs) == .lt;
        }
    }.lessThan);
}

test "query.summary handles nested select where" {
    const outcome = try pg_query.query.summary(
        std.testing.allocator,
        "SELECT * FROM test WHERE col1 = (SELECT col2 FROM test2 WHERE col3 = 123)",
        -1,
    );
    var result = try support.unwrapOk(pg_query.SummaryResult, outcome);
    defer result.deinit();

    const tables = try result.tables(std.testing.allocator);
    defer std.testing.allocator.free(tables);
    sortStrings(tables);

    try std.testing.expectEqual(@as(usize, 2), tables.len);
    try std.testing.expectEqualStrings("test", tables[0]);
    try std.testing.expectEqualStrings("test2", tables[1]);
    try std.testing.expectEqual(@as(usize, 2), result.filterColumns().len);
    try std.testing.expectEqualStrings("SelectStmt", result.statementTypes()[0]);
}

test "query.summary handles recursion without error" {
    const sql =
        \\SELECT * FROM "t0"
        \\JOIN "t1" ON (1) JOIN "t2" ON (1) JOIN "t3" ON (1) JOIN "t4" ON (1) JOIN "t5" ON (1)
        \\JOIN "t6" ON (1) JOIN "t7" ON (1) JOIN "t8" ON (1) JOIN "t9" ON (1) JOIN "t10" ON (1)
        \\JOIN "t11" ON (1) JOIN "t12" ON (1) JOIN "t13" ON (1) JOIN "t14" ON (1) JOIN "t15" ON (1)
        \\JOIN "t16" ON (1) JOIN "t17" ON (1) JOIN "t18" ON (1) JOIN "t19" ON (1) JOIN "t20" ON (1)
        \\JOIN "t21" ON (1) JOIN "t22" ON (1) JOIN "t23" ON (1) JOIN "t24" ON (1) JOIN "t25" ON (1)
        \\JOIN "t26" ON (1) JOIN "t27" ON (1) JOIN "t28" ON (1) JOIN "t29" ON (1)
    ;

    const outcome = try pg_query.query.summary(std.testing.allocator, sql, -1);
    var result = try support.unwrapOk(pg_query.SummaryResult, outcome);
    defer result.deinit();

    const tables = try result.tables(std.testing.allocator);
    defer std.testing.allocator.free(tables);
    try std.testing.expectEqual(@as(usize, 30), tables.len);
    try std.testing.expectEqualStrings("SelectStmt", result.statementTypes()[0]);
}

test "query.summary handles merge" {
    const sql =
        \\WITH cte AS (SELECT * FROM g.other_table CROSS JOIN p)
        \\MERGE INTO my_table USING cte ON (id=oid)
        \\WHEN MATCHED THEN UPDATE SET a=b
        \\WHEN NOT MATCHED THEN INSERT (id, a) VALUES (oid, b);
    ;
    const outcome = try pg_query.query.summary(std.testing.allocator, sql, -1);
    var result = try support.unwrapOk(pg_query.SummaryResult, outcome);
    defer result.deinit();

    const select_tables = try result.selectTables(std.testing.allocator);
    defer std.testing.allocator.free(select_tables);
    sortStrings(select_tables);

    const dml_tables = try result.dmlTables(std.testing.allocator);
    defer std.testing.allocator.free(dml_tables);
    sortStrings(dml_tables);

    try std.testing.expectEqual(@as(usize, 2), select_tables.len);
    try std.testing.expectEqualStrings("g.other_table", select_tables[0]);
    try std.testing.expectEqualStrings("p", select_tables[1]);
    try std.testing.expectEqual(@as(usize, 1), dml_tables.len);
    try std.testing.expectEqualStrings("my_table", dml_tables[0]);
    try std.testing.expectEqual(@as(usize, 1), result.cteNames().len);
    try std.testing.expectEqualStrings("cte", result.cteNames()[0]);
}

test "query.summary handles utility statements" {
    const cases = [_]struct {
        sql: []const u8,
        statement_type: []const u8,
        table: ?[]const u8 = null,
    }{
        .{ .sql = "ALTER TABLE test ADD PRIMARY KEY (gid)", .statement_type = "AlterTableStmt", .table = "test" },
        .{ .sql = "SET statement_timeout=1", .statement_type = "VariableSetStmt" },
        .{ .sql = "SHOW work_mem", .statement_type = "VariableShowStmt" },
        .{ .sql = "COPY test (id) TO stdout", .statement_type = "CopyStmt", .table = "test" },
        .{ .sql = "COMMIT", .statement_type = "TransactionStmt" },
        .{ .sql = "CHECKPOINT", .statement_type = "CheckPointStmt" },
        .{ .sql = "VACUUM my_table", .statement_type = "VacuumStmt", .table = "my_table" },
        .{ .sql = "EXPLAIN DELETE FROM test", .statement_type = "ExplainStmt", .table = "test" },
    };

    for (cases) |case| {
        const outcome = try pg_query.query.summary(std.testing.allocator, case.sql, -1);
        var result = try support.unwrapOk(pg_query.SummaryResult, outcome);
        defer result.deinit();

        try std.testing.expectEqualStrings(case.statement_type, result.statementTypes()[0]);
        if (case.table) |table| {
            const tables = try result.tables(std.testing.allocator);
            defer std.testing.allocator.free(tables);
            try std.testing.expect(tables.len >= 1);
            try std.testing.expectEqualStrings(table, tables[0]);
        }
    }
}

test "query.summary handles errors" {
    const bad_random = try pg_query.query.summary(std.testing.allocator, "CREATE RANDOM ix_test ON contacts.person;", -1);
    try support.expectErrorKind(pg_query.SummaryResult, bad_random, .summary, "syntax error at or near \"RANDOM\"");

    const bad_string = try pg_query.query.summary(std.testing.allocator, "SELECT 'ERR", -1);
    try support.expectErrorKind(
        pg_query.SummaryResult,
        bad_string,
        .summary,
        "unterminated quoted string at or near \"'ERR\"",
    );
}

test "query.summary handles create table family" {
    const create_table = try pg_query.query.summary(std.testing.allocator, "CREATE TABLE test (a int4)", -1);
    var create_table_result = try support.unwrapOk(pg_query.SummaryResult, create_table);
    defer create_table_result.deinit();
    const create_table_tables = try create_table_result.tables(std.testing.allocator);
    defer std.testing.allocator.free(create_table_tables);
    try std.testing.expectEqualStrings("test", create_table_tables[0]);
    try std.testing.expectEqualStrings("CreateStmt", create_table_result.statementTypes()[0]);

    const create_as = try pg_query.query.summary(std.testing.allocator, "CREATE TABLE foo AS SELECT * FROM bar;", -1);
    var create_as_result = try support.unwrapOk(pg_query.SummaryResult, create_as);
    defer create_as_result.deinit();
    const create_as_tables = try create_as_result.tables(std.testing.allocator);
    defer std.testing.allocator.free(create_as_tables);
    try std.testing.expect(create_as_tables.len >= 2);
}

test "query.summary handles view and materialized view family" {
    const view_outcome = try pg_query.query.summary(std.testing.allocator, "CREATE VIEW myview AS SELECT * FROM mytab", -1);
    var view_result = try support.unwrapOk(pg_query.SummaryResult, view_outcome);
    defer view_result.deinit();
    try std.testing.expectEqualStrings("ViewStmt", view_result.statementTypes()[0]);

    const refresh_outcome = try pg_query.query.summary(std.testing.allocator, "REFRESH MATERIALIZED VIEW myview", -1);
    var refresh_result = try support.unwrapOk(pg_query.SummaryResult, refresh_outcome);
    defer refresh_result.deinit();
    try std.testing.expectEqualStrings("RefreshMatViewStmt", refresh_result.statementTypes()[0]);
}

test "query.summary handles create index and trigger family" {
    const index_outcome = try pg_query.query.summary(
        std.testing.allocator,
        "CREATE INDEX testidx ON test USING btree (a, (lower(b) || upper(c))) WHERE pow(a, 2) > 25",
        -1,
    );
    var index_result = try support.unwrapOk(pg_query.SummaryResult, index_outcome);
    defer index_result.deinit();
    try std.testing.expectEqualStrings("IndexStmt", index_result.statementTypes()[0]);

    const trig_outcome = try pg_query.query.summary(
        std.testing.allocator,
        "CREATE TRIGGER check_update BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE PROCEDURE check_account_update()",
        -1,
    );
    var trig_result = try support.unwrapOk(pg_query.SummaryResult, trig_outcome);
    defer trig_result.deinit();
    try std.testing.expectEqualStrings("CreateTrigStmt", trig_result.statementTypes()[0]);
}

test "query.summary handles schema grant truncate and lock family" {
    const cases = [_]struct {
        sql: []const u8,
        statement_type: []const u8,
    }{
        .{ .sql = "CREATE SCHEMA IF NOT EXISTS test AUTHORIZATION joe", .statement_type = "CreateSchemaStmt" },
        .{ .sql = "GRANT INSERT, UPDATE ON mytable TO myuser", .statement_type = "GrantStmt" },
        .{ .sql = "TRUNCATE bigtable RESTART IDENTITY", .statement_type = "TruncateStmt" },
        .{ .sql = "LOCK TABLE public.schema_migrations IN ACCESS SHARE MODE", .statement_type = "LockStmt" },
    };

    for (cases) |case| {
        const outcome = try pg_query.query.summary(std.testing.allocator, case.sql, -1);
        var result = try support.unwrapOk(pg_query.SummaryResult, outcome);
        defer result.deinit();
        try std.testing.expectEqualStrings(case.statement_type, result.statementTypes()[0]);
    }
}

test "query.summary handles function discovery family" {
    const multiline_sql =
        \\CREATE OR REPLACE FUNCTION thing(parameter_thing text)
        \\RETURNS bigint AS
        \\$BODY$
        \\DECLARE
        \\        local_thing_id BIGINT := 0;
        \\BEGIN
        \\        SELECT thing_id INTO local_thing_id FROM thing_map
        \\        WHERE thing_map_field = parameter_thing
        \\        ORDER BY 1 LIMIT 1;
        \\
        \\        IF NOT FOUND THEN
        \\                local_thing_id = 0;
        \\        END IF;
        \\        RETURN local_thing_id;
        \\END;
        \\$BODY$
        \\LANGUAGE plpgsql STABLE
    ;
    const multiline_outcome = try pg_query.query.summary(std.testing.allocator, multiline_sql, -1);
    var multiline_result = try support.unwrapOk(pg_query.SummaryResult, multiline_outcome);
    defer multiline_result.deinit();
    const ddl_functions = try multiline_result.ddlFunctions(std.testing.allocator);
    defer std.testing.allocator.free(ddl_functions);
    try std.testing.expectEqual(@as(usize, 1), ddl_functions.len);
    try std.testing.expectEqualStrings("thing", ddl_functions[0]);

    const call_outcome = try pg_query.query.summary(std.testing.allocator, "CALL testfunc(1);", -1);
    var call_result = try support.unwrapOk(pg_query.SummaryResult, call_outcome);
    defer call_result.deinit();
    const call_functions = try call_result.callFunctions(std.testing.allocator);
    defer std.testing.allocator.free(call_functions);
    try std.testing.expectEqual(@as(usize, 1), call_functions.len);
    try std.testing.expectEqualStrings("testfunc", call_functions[0]);
}
