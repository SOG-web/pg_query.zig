const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

fn expectSummaryTruncate(sql: []const u8, limit: i32, expected: []const u8) !void {
    const outcome = try pg_query.query.summary(std.testing.allocator, sql, limit);
    var result = try support.unwrapOk(pg_query.SummaryResult, outcome);
    defer result.deinit();

    try std.testing.expectEqualStrings(expected, result.truncated_query);
}

test "query.summary truncates target list and cte" {
    try expectSummaryTruncate("SELECT a, b, c, d, e, f FROM xyz WHERE a = b", 40, "SELECT ... FROM xyz WHERE a = b");
    try expectSummaryTruncate("WITH x AS (SELECT * FROM y) SELECT * FROM x", 40, "WITH x AS (...) SELECT * FROM x");
}

test "query.summary truncates insert update and conflict" {
    try expectSummaryTruncate("INSERT INTO \"x\" (a, b, c, d, e, f) VALUES ($1)", 32, "INSERT INTO x (...) VALUES ($1)");
    try expectSummaryTruncate("UPDATE x SET a = 1, c = 2, e = 'str'", 30, "UPDATE x SET ... = ...");
    try expectSummaryTruncate(
        "INSERT INTO y(a) VALUES(1) ON CONFLICT DO UPDATE SET a = 123456789",
        64,
        "INSERT INTO y (a) VALUES (1) ON CONFLICT DO UPDATE SET ... = ...",
    );
}

test "query.summary truncates comments and simple statements" {
    try expectSummaryTruncate("SELECT $1 /* application:test */", 100, "SELECT $1");
    try expectSummaryTruncate("SELECT * FROM t", 10, "SELECT ...");
    try expectSummaryTruncate(
        "SELECT CASE WHEN $2.typtype = $1 THEN $2.typtypmod ELSE $1.atttypmod END",
        50,
        "SELECT ...",
    );
}
