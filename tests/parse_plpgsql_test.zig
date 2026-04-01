const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

test "query.parsePlpgsql handles simple function" {
    const sql =
        \\CREATE OR REPLACE FUNCTION cs_fmt_browser_version(v_name varchar, v_version varchar)
        \\RETURNS varchar AS $$
        \\BEGIN
        \\    IF v_version IS NULL THEN
        \\        RETURN v_name;
        \\    END IF;
        \\    RETURN v_name || '/' || v_version;
        \\END;
        \\$$ LANGUAGE plpgsql;
    ;

    const outcome = try pg_query.query.parsePlpgsql(std.testing.allocator, sql);
    var result = try support.unwrapOk(pg_query.PlpgsqlParseResult, outcome);
    defer result.deinit();

    try std.testing.expect(std.mem.indexOf(u8, result.functions_json, "\"PLpgSQL_function\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.functions_json, "\"PLpgSQL_stmt_if\"") != null);
}

test "query.parsePlpgsql handles query function" {
    const sql =
        \\CREATE OR REPLACE FUNCTION fn(input integer) RETURNS jsonb LANGUAGE plpgsql STABLE AS
        \\'
        \\DECLARE
        \\    result jsonb;
        \\BEGIN
        \\    SELECT details FROM t INTO result WHERE col = input;
        \\    RETURN result;
        \\END;
        \\';
    ;

    const outcome = try pg_query.query.parsePlpgsql(std.testing.allocator, sql);
    var result = try support.unwrapOk(pg_query.PlpgsqlParseResult, outcome);
    defer result.deinit();

    try std.testing.expect(std.mem.indexOf(u8, result.functions_json, "\"PLpgSQL_stmt_execsql\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.functions_json, "\"PLpgSQL_stmt_return\"") != null);
}

test "query.parsePlpgsql returns parse errors" {
    const outcome = try pg_query.query.parsePlpgsql(std.testing.allocator, "CREATE RANDOM ix_test ON contacts.person;");
    try support.expectErrorKind(
        pg_query.PlpgsqlParseResult,
        outcome,
        .plpgsql,
        "syntax error at or near \"RANDOM\"",
    );
}
