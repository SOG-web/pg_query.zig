const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

fn expectTruncate(sql: []const u8, limit: usize, expected: []const u8) !void {
    const outcome = try pg_query.query.parse(std.testing.allocator, sql);
    var parsed = try support.unwrapOk(pg_query.query.ParseResult, outcome);
    defer parsed.deinit();

    const truncate_outcome = try parsed.truncate(std.testing.allocator, limit);
    var truncated = try support.unwrapOk(pg_query.OwnedString, truncate_outcome);
    defer truncated.deinit();

    try std.testing.expectEqualStrings(expected, truncated.value);
}

test "query.truncate omits target list" {
    try expectTruncate("SELECT a, b, c, d, e, f FROM xyz WHERE a = b", 40, "SELECT ... FROM xyz WHERE a = b");
}

test "query.truncate omits comments" {
    try expectTruncate("SELECT $1 /* application:test */", 100, "SELECT $1");
}

test "query.truncate handles update target list" {
    try expectTruncate("UPDATE x SET a = 1, c = 2, e = 'str'", 30, "UPDATE x SET ... = ...");
}
