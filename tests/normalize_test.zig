const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

test "query.normalize handles simple query" {
    const outcome = try pg_query.query.normalize(std.testing.allocator, "SELECT 1");
    var normalized = try support.unwrapOk(pg_query.OwnedString, outcome);
    defer normalized.deinit();

    try std.testing.expectEqualStrings("SELECT $1", normalized.value);
}

test "query.normalize handles IN lists" {
    const outcome = try pg_query.query.normalize(
        std.testing.allocator,
        "SELECT 1 FROM x WHERE y = 12561 AND z = '124' AND b IN (1, 2, 3)",
    );
    var normalized = try support.unwrapOk(pg_query.OwnedString, outcome);
    defer normalized.deinit();

    try std.testing.expectEqualStrings(
        "SELECT $1 FROM x WHERE y = $2 AND z = $3 AND b IN ($4, $5, $6)",
        normalized.value,
    );
}

test "query.normalize handles subselects" {
    const outcome = try pg_query.query.normalize(
        std.testing.allocator,
        "SELECT 1 FROM x WHERE y = (SELECT 123 FROM a WHERE z = 'bla')",
    );
    var normalized = try support.unwrapOk(pg_query.OwnedString, outcome);
    defer normalized.deinit();

    try std.testing.expectEqualStrings(
        "SELECT $1 FROM x WHERE y = (SELECT $2 FROM a WHERE z = $3)",
        normalized.value,
    );
}

test "query.normalize returns parse errors" {
    const outcome = try pg_query.query.normalize(
        std.testing.allocator,
        "CREATE RANDOM ix_test ON contacts.person;",
    );
    try support.expectErrorKind(
        pg_query.OwnedString,
        outcome,
        .normalize,
        "syntax error at or near \"RANDOM\"",
    );
}

test "query.normalize handles DEALLOCATE" {
    const outcome = try pg_query.query.normalize(std.testing.allocator, "DEALLOCATE bla; SELECT 1");
    var normalized = try support.unwrapOk(pg_query.OwnedString, outcome);
    defer normalized.deinit();

    try std.testing.expectEqualStrings("DEALLOCATE bla; SELECT $1", normalized.value);
}
