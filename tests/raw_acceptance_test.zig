const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

fn assertRawMatchesQuery(sql: []const u8) !void {
    const raw_outcome = try pg_query.raw.parse(std.testing.allocator, sql);
    var raw = try support.unwrapOk(pg_query.raw.RawParseResult, raw_outcome);
    defer raw.deinit();

    const raw_deparse_outcome = try pg_query.raw.deparse(std.testing.allocator, &raw);
    var raw_deparse = try support.unwrapOk(pg_query.OwnedString, raw_deparse_outcome);
    defer raw_deparse.deinit();

    const raw_fp_outcome = try pg_query.raw.fingerprint(std.testing.allocator, &raw);
    var raw_fp = try support.unwrapOk(pg_query.Fingerprint, raw_fp_outcome);
    defer raw_fp.deinit();

    const query_outcome = try pg_query.query.parse(std.testing.allocator, sql);
    var query = try support.unwrapOk(pg_query.query.ParseResult, query_outcome);
    defer query.deinit();

    const query_deparse_outcome = try query.deparse(std.testing.allocator);
    var query_deparse = try support.unwrapOk(pg_query.OwnedString, query_deparse_outcome);
    defer query_deparse.deinit();

    const query_fp_outcome = try pg_query.query.fingerprint(std.testing.allocator, sql);
    var query_fp = try support.unwrapOk(pg_query.Fingerprint, query_fp_outcome);
    defer query_fp.deinit();

    try std.testing.expectEqual(query.stmtCount(), @as(usize, 1));
    try std.testing.expectEqualStrings(query_fp.hex, raw_fp.hex);
    try std.testing.expectEqualStrings(query_deparse.value, raw_deparse.value);
}

test "raw.parse acceptance select family" {
    const queries = [_][]const u8{
        "SELECT 1",
        "SELECT * FROM t",
        "SELECT DISTINCT ON (a) c, d FROM t ORDER BY a",
        "SELECT * FROM t WHERE a IN (1, 2, 3)",
        "SELECT * FROM t ORDER BY a DESC NULLS LAST",
        "SELECT * FROM t LIMIT 10 OFFSET 5",
        "SELECT * FROM t1 JOIN t2 ON t1.id = t2.id",
        "WITH cte AS (SELECT 1 AS a) SELECT * FROM cte",
        "SELECT * FROM (SELECT * FROM t) AS sub",
    };
    for (queries) |sql| try assertRawMatchesQuery(sql);
}

test "raw.parse acceptance dml and utility family" {
    const queries = [_][]const u8{
        "INSERT INTO test (a, b) VALUES ($1, $2)",
        "UPDATE test SET a = 1 WHERE id = 2",
        "DELETE FROM test WHERE id = 1",
        "MERGE INTO my_table USING other_table ON (my_table.id = other_table.id) WHEN MATCHED THEN UPDATE SET a = other_table.a",
        "ALTER TABLE test ADD PRIMARY KEY (gid)",
        "COPY test (id) TO stdout",
        "VACUUM my_table",
        "EXPLAIN DELETE FROM test",
    };
    for (queries) |sql| try assertRawMatchesQuery(sql);
}

test "raw.parse acceptance extended select family" {
    const queries = [_][]const u8{
        "SELECT * FROM t WHERE a BETWEEN 1 AND 10",
        "SELECT * FROM t WHERE a LIKE 'foo%'",
        "SELECT a, count(*) FROM t GROUP BY a HAVING count(*) > 1",
        "SELECT a, ROW_NUMBER() OVER (PARTITION BY b ORDER BY a) FROM t",
        "SELECT a FROM t1 UNION ALL SELECT a FROM t2",
        "SELECT * FROM t FOR UPDATE SKIP LOCKED",
        "SELECT * FROM t TABLESAMPLE SYSTEM (10)",
        "SELECT * FROM (VALUES (1, 'a'), (2, 'b')) AS t(id, name)",
        "SELECT ARRAY[1, 2, 3]",
        "SELECT data ->> 'key' FROM t",
        "SELECT concat_ws(', ', 'a', 'b', 'c')",
    };
    for (queries) |sql| try assertRawMatchesQuery(sql);
}

test "raw.parse acceptance extended utility family" {
    const queries = [_][]const u8{
        "CREATE TABLE test (a int4)",
        "CREATE TABLE foo AS SELECT * FROM bar",
        "CREATE VIEW myview AS SELECT * FROM mytab",
        "REFRESH MATERIALIZED VIEW myview",
        "CREATE INDEX testidx ON test USING btree (a, (lower(b) || upper(c))) WHERE pow(a, 2) > 25",
        "CREATE TRIGGER check_update BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE PROCEDURE check_account_update()",
        "GRANT INSERT, UPDATE ON mytable TO myuser",
        "TRUNCATE bigtable RESTART IDENTITY",
        "LOCK TABLE public.schema_migrations IN ACCESS SHARE MODE",
    };
    for (queries) |sql| try assertRawMatchesQuery(sql);
}
