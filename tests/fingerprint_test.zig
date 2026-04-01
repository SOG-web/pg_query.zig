const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

fn fingerprintHex(sql: []const u8) ![]u8 {
    const outcome = try pg_query.query.fingerprint(std.testing.allocator, sql);
    var result = try support.unwrapOk(pg_query.Fingerprint, outcome);
    defer result.deinit();
    return try std.testing.allocator.dupe(u8, result.hex);
}

test "query.fingerprint handles simple statement" {
    const outcome = try pg_query.query.fingerprint(
        std.testing.allocator,
        "SELECT * FROM contacts.person WHERE id IN (1, 2, 3, 4);",
    );
    var result = try support.unwrapOk(pg_query.Fingerprint, outcome);
    defer result.deinit();

    try std.testing.expectEqualStrings("643d2a3c294ab8a7", result.hex);
}

test "query.fingerprint returns parse errors" {
    const outcome = try pg_query.query.fingerprint(
        std.testing.allocator,
        "CREATE RANDOM ix_test ON contacts.person;",
    );
    try support.expectErrorKind(
        pg_query.Fingerprint,
        outcome,
        .fingerprint,
        "syntax error at or near \"RANDOM\"",
    );
}

test "query.fingerprint ignores aliases" {
    const q1 = try fingerprintHex("SELECT a AS b");
    defer std.testing.allocator.free(q1);
    const q2 = try fingerprintHex("SELECT a AS c");
    defer std.testing.allocator.free(q2);

    try std.testing.expectEqualStrings(q1, q2);
}

test "query.fingerprint ignores IN list size" {
    const q1 = try fingerprintHex("SELECT * FROM x WHERE y IN ($1, $2, $3)");
    defer std.testing.allocator.free(q1);
    const q2 = try fingerprintHex("SELECT * FROM x WHERE y IN ($1)");
    defer std.testing.allocator.free(q2);

    try std.testing.expectEqualStrings(q1, q2);
}

test "query.fingerprint distinguishes multi statement changes" {
    const q1 = try fingerprintHex("SET x=$1; SELECT A");
    defer std.testing.allocator.free(q1);
    const q2 = try fingerprintHex("SELECT a");
    defer std.testing.allocator.free(q2);

    try std.testing.expect(!std.mem.eql(u8, q1, q2));
}
