const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

test "raw.parse and query.parse agree on statement count" {
    const sql = "SELECT 1";

    const raw_outcome = try pg_query.raw.parse(std.testing.allocator, sql);
    var raw_result = try support.unwrapOk(pg_query.raw.RawParseResult, raw_outcome);
    defer raw_result.deinit();

    const query_outcome = try pg_query.query.parse(std.testing.allocator, sql);
    var query_result = try support.unwrapOk(pg_query.query.ParseResult, query_outcome);
    defer query_result.deinit();

    try std.testing.expectEqual(@as(usize, 1), query_result.stmtCount());

    const deparse_outcome = try pg_query.raw.deparse(std.testing.allocator, &raw_result);
    var deparsed = try support.unwrapOk(pg_query.OwnedString, deparse_outcome);
    defer deparsed.deinit();
    try std.testing.expectEqualStrings("SELECT 1", deparsed.value);
}

test "raw.fingerprint matches high-level fingerprint" {
    const sql = "SELECT * FROM contacts WHERE name='Paul'";

    const raw_outcome = try pg_query.raw.parse(std.testing.allocator, sql);
    var raw_result = try support.unwrapOk(pg_query.raw.RawParseResult, raw_outcome);
    defer raw_result.deinit();

    const raw_fp_outcome = try pg_query.raw.fingerprint(std.testing.allocator, &raw_result);
    var raw_fp = try support.unwrapOk(pg_query.Fingerprint, raw_fp_outcome);
    defer raw_fp.deinit();

    const fp_outcome = try pg_query.query.fingerprint(std.testing.allocator, sql);
    var fp = try support.unwrapOk(pg_query.Fingerprint, fp_outcome);
    defer fp.deinit();

    try std.testing.expectEqual(fp.value, raw_fp.value);
    try std.testing.expectEqualStrings(fp.hex, raw_fp.hex);
}
