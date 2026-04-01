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

fn expectRawAndQueryParity(sql: []const u8, expected_stmt_count: usize, expected_stmt_types: []const []const u8) !void {
    const raw_outcome = try pg_query.raw.parse(std.testing.allocator, sql);
    var raw_result = try support.unwrapOk(pg_query.raw.RawParseResult, raw_outcome);
    defer raw_result.deinit();

    const parsed_outcome = try pg_query.query.parse(std.testing.allocator, sql);
    var parsed_result = try support.unwrapOk(pg_query.query.ParseResult, parsed_outcome);
    defer parsed_result.deinit();

    const via_raw_outcome = try pg_query.query.parseViaRawDetailed(std.testing.allocator, sql);
    var via_raw_result = try support.unwrapOk(pg_query.query.ParseResult, via_raw_outcome);
    defer via_raw_result.deinit();

    try std.testing.expectEqual(expected_stmt_count, parsed_result.stmtCount());
    try std.testing.expectEqual(expected_stmt_count, via_raw_result.stmtCount());
    try std.testing.expectEqual(expected_stmt_types.len, parsed_result.statementTypes().len);
    for (expected_stmt_types, parsed_result.statementTypes()) |want, got| {
        try std.testing.expectEqualStrings(want, got);
    }
    try std.testing.expectEqual(expected_stmt_types.len, via_raw_result.statementTypes().len);
    for (expected_stmt_types, via_raw_result.statementTypes()) |want, got| {
        try std.testing.expectEqualStrings(want, got);
    }

    var raw_deparsed = try support.unwrapOk(pg_query.OwnedString, try pg_query.raw.deparse(std.testing.allocator, &raw_result));
    defer raw_deparsed.deinit();
    if (expected_stmt_count == 0) {
        try std.testing.expectEqual(@as(usize, 0), raw_deparsed.value.len);
    } else {
        try std.testing.expect(raw_deparsed.value.len != 0);
    }

    const parsed_tables = try parsed_result.tables(std.testing.allocator);
    defer std.testing.allocator.free(parsed_tables);
    const via_raw_tables = try via_raw_result.tables(std.testing.allocator);
    defer std.testing.allocator.free(via_raw_tables);
    sortStrings(parsed_tables);
    sortStrings(via_raw_tables);
    try std.testing.expectEqual(parsed_tables.len, via_raw_tables.len);
    for (parsed_tables, via_raw_tables) |lhs, rhs| {
        try std.testing.expectEqualStrings(lhs, rhs);
    }

    const reparsed_outcome = try pg_query.query.parse(std.testing.allocator, raw_deparsed.value);
    var reparsed_result = try support.unwrapOk(pg_query.query.ParseResult, reparsed_outcome);
    defer reparsed_result.deinit();
    const reparsed_tables = try reparsed_result.tables(std.testing.allocator);
    defer std.testing.allocator.free(reparsed_tables);
    sortStrings(parsed_tables);
    sortStrings(reparsed_tables);
    try std.testing.expectEqual(parsed_tables.len, reparsed_tables.len);
    for (parsed_tables, reparsed_tables) |lhs, rhs| {
        try std.testing.expectEqualStrings(lhs, rhs);
    }
}

test "raw parse parity covers basic select family" {
    try expectRawAndQueryParity("SELECT 1", 1, &.{"SelectStmt"});
    try expectRawAndQueryParity("SELECT * FROM users", 1, &.{"SelectStmt"});
    try expectRawAndQueryParity("SELECT 1; SELECT 2; SELECT 3", 3, &.{"SelectStmt"});
    try expectRawAndQueryParity("-- just a comment", 0, &.{});
}

test "raw parse parity covers joins ctes and subqueries" {
    try expectRawAndQueryParity(
        "SELECT * FROM users u JOIN orders o ON u.id = o.user_id",
        1,
        &.{"SelectStmt"},
    );
    try expectRawAndQueryParity(
        "WITH active_users AS (SELECT * FROM users WHERE active = true) SELECT * FROM active_users",
        1,
        &.{"SelectStmt"},
    );
    try expectRawAndQueryParity(
        "SELECT * FROM users WHERE id IN (SELECT user_id FROM orders)",
        1,
        &.{"SelectStmt"},
    );
}

test "raw parse parity covers ddl and utility statements" {
    try expectRawAndQueryParity("CREATE TABLE test (id int, name text)", 1, &.{"CreateStmt"});
    try expectRawAndQueryParity("DROP TABLE users", 1, &.{"DropStmt"});
    try expectRawAndQueryParity("CREATE INDEX idx_users_name ON users (name)", 1, &.{"IndexStmt"});
    try expectRawAndQueryParity("EXPLAIN SELECT * FROM users WHERE id = 1", 1, &.{ "ExplainStmt", "SelectStmt" });
    try expectRawAndQueryParity("BEGIN", 1, &.{"TransactionStmt"});
    try expectRawAndQueryParity("VACUUM users", 1, &.{"VacuumStmt"});
}
