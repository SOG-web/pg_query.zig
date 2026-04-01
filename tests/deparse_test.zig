const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

fn expectDeparse(input: []const u8, expected: []const u8) !void {
    const outcome = try pg_query.query.parse(std.testing.allocator, input);
    var parsed = try support.unwrapOk(pg_query.query.ParseResult, outcome);
    defer parsed.deinit();

    const deparse_outcome = try parsed.deparse(std.testing.allocator);
    var deparsed = try support.unwrapOk(pg_query.OwnedString, deparse_outcome);
    defer deparsed.deinit();

    try std.testing.expectEqualStrings(expected, deparsed.value);
}

test "query.deparse handles simple select" {
    try expectDeparse("SELECT a AS b FROM x WHERE y = 5 AND z = y", "SELECT a AS b FROM x WHERE y = 5 AND z = y");
}

test "query.deparse handles distinct on" {
    try expectDeparse("SELECT DISTINCT ON (a) a, b FROM c", "SELECT DISTINCT ON (a) a, b FROM c");
}

test "query.deparse handles order by nulls" {
    try expectDeparse("SELECT * FROM a ORDER BY x ASC NULLS FIRST", "SELECT * FROM a ORDER BY x ASC NULLS FIRST");
}

test "query.deparse handles cte" {
    try expectDeparse(
        "WITH t AS (SELECT random() AS x FROM generate_series(1, 3)) SELECT * FROM t",
        "WITH t AS (SELECT random() AS x FROM generate_series(1, 3)) SELECT * FROM t",
    );
}
