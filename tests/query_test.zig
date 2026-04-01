const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

test "query.parse handles simple query" {
    const outcome = try pg_query.query.parse(std.testing.allocator, "SELECT * FROM contacts");
    var result = try support.unwrapOk(pg_query.query.ParseResult, outcome);
    defer result.deinit();

    const tables = try result.tables(std.testing.allocator);
    defer std.testing.allocator.free(tables);
    try std.testing.expectEqual(@as(usize, 1), tables.len);
    try std.testing.expectEqualStrings("contacts", tables[0]);

    const statement_types = result.statementTypes();
    try std.testing.expectEqual(@as(usize, 1), statement_types.len);
    try std.testing.expectEqualStrings("SelectStmt", statement_types[0]);
}

test "query.parse returns parse errors" {
    const outcome = try pg_query.query.parse(std.testing.allocator, "CREATE RANDOM ix_test ON contacts.person;");
    try support.expectErrorKind(pg_query.query.ParseResult, outcome, .parse, "syntax error at or near \"RANDOM\"");
}

test "query.normalize" {
    const outcome = try pg_query.query.normalize(std.testing.allocator, "SELECT * FROM contacts WHERE name='Paul'");
    var normalized = try support.unwrapOk(pg_query.OwnedString, outcome);
    defer normalized.deinit();

    try std.testing.expectEqualStrings("SELECT * FROM contacts WHERE name=$1", normalized.value);
}

test "query.fingerprint" {
    const outcome = try pg_query.query.fingerprint(std.testing.allocator, "SELECT * FROM contacts WHERE name='Paul'");
    var result = try support.unwrapOk(pg_query.Fingerprint, outcome);
    defer result.deinit();

    try std.testing.expectEqualStrings("0e2581a461ece536", result.hex);
}

test "query.splitWithParser" {
    const sql = "select /*;*/ 1; select \"2;\", (select 3);";
    const outcome = try pg_query.query.splitWithParser(std.testing.allocator, sql);
    var result = try support.unwrapOk(pg_query.SplitResult, outcome);
    defer result.deinit();

    try std.testing.expectEqual(@as(usize, 2), result.stmts.len);
    try std.testing.expectEqualStrings("select /*;*/ 1", result.stmts[0].slice(sql));
    try std.testing.expectEqualStrings(" select \"2;\", (select 3)", result.stmts[1].slice(sql));
}

test "query.splitWithScanner tolerates malformed SQL" {
    const sql = "select /*;*/ 1; asdf; select \"2;\", (select 3); asdf";
    const outcome = try pg_query.query.splitWithScanner(std.testing.allocator, sql);
    var result = try support.unwrapOk(pg_query.SplitResult, outcome);
    defer result.deinit();

    try std.testing.expectEqual(@as(usize, 2), result.stmts.len);
    try std.testing.expectEqualStrings("select /*;*/ 1", result.stmts[0].slice(sql));
    try std.testing.expectEqualStrings(" select \"2;\", (select 3)", result.stmts[1].slice(sql));
}
