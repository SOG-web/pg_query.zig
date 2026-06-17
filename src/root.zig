const std = @import("std");

const pg_query = @import("pg_query.zig");

pub const proto = @import("pg_query_proto");
/// C bindings to libpg_query
pub const libpg_query = @import("c");

pub const parse = pg_query.parse;
pub const normalize = pg_query.normalize;
pub const normalizeUtility = pg_query.normalizeUtility;
pub const fingerprint = pg_query.fingerprint;
pub const splitWithScanner = pg_query.splitWithScanner;
pub const splitWithParser = pg_query.splitWithParser;
pub const parsePlpgsql = pg_query.parsePlpgsql;
pub const isUtilityStmt = pg_query.isUtilityStmt;
pub const parseProtobuf = pg_query.parseProtobuf;
pub const scanProtobuf = pg_query.scanProtobuf;

pub const ParseResult = pg_query.ParseResult;
pub const Error = pg_query.Error;
pub const FingerPrintResult = pg_query.FingerPrintResult;
pub const NormalizeResult = pg_query.NormalizeResult;
pub const SplitResult = pg_query.SplitResult;
pub const ProtobufParseResult = pg_query.ProtobufParseResult;
pub const ProtobufScanResult = pg_query.ProtobufScanResult;

test "parse" {
    var result = try parse(std.testing.allocator, "SELECT 1");
    defer result.deinit();
    try std.testing.expect(result.parse_tree.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, result.parse_tree, "SelectStmt") != null);
}

test "parse empty input" {
    const result = parse(std.testing.allocator, "");
    try std.testing.expectError(error.EmptyInput, result);
}

test "parse syntax error" {
    const result = parse(std.testing.allocator, "SELECT * FROM");
    try std.testing.expectError(error.ParseError, result);
}

test "normalize" {
    var result = try normalize(std.testing.allocator, "SELECT * FROM users WHERE age > 30");
    defer result.deinit();
    try std.testing.expectEqualStrings("SELECT * FROM users WHERE age > $1", result.normalized);
}

test "normalize empty input" {
    const result = normalize(std.testing.allocator, "");
    try std.testing.expectError(error.EmptyInput, result);
}

test "normalize multiple literals" {
    var result = try normalize(std.testing.allocator, "SELECT * FROM users WHERE age > 30 AND name = 'foo'");
    defer result.deinit();
    try std.testing.expectEqualStrings("SELECT * FROM users WHERE age > $1 AND name = $2", result.normalized);
}

test "normalize utility" {
    var result = try normalizeUtility(std.testing.allocator, "SELECT 1");
    defer result.deinit();
    try std.testing.expect(result.normalized.len > 0);
}

test "normalize utility empty input" {
    const result = normalizeUtility(std.testing.allocator, "");
    try std.testing.expectError(error.EmptyInput, result);
}

test "fingerprint" {
    var result = try fingerprint(std.testing.allocator, "SELECT 1");
    defer result.deinit();
    try std.testing.expect(result.hash != 0);
    try std.testing.expectEqual(@as(usize, 16), result.hex.len);
}

test "fingerprint same query same hash" {
    var r1 = try fingerprint(std.testing.allocator, "SELECT 1");
    defer r1.deinit();
    var r2 = try fingerprint(std.testing.allocator, "SELECT 1");
    defer r2.deinit();
    try std.testing.expectEqual(r1.hash, r2.hash);
}

test "fingerprint different query different hash" {
    var r1 = try fingerprint(std.testing.allocator, "SELECT 1");
    defer r1.deinit();
    var r2 = try fingerprint(std.testing.allocator, "SELECT * FROM users");
    defer r2.deinit();
    try std.testing.expect(r1.hash != r2.hash);
}

test "fingerprint empty input" {
    const result = fingerprint(std.testing.allocator, "");
    try std.testing.expectError(error.EmptyInput, result);
}

test "split with scanner" {
    var result = try splitWithScanner(std.testing.allocator, "SELECT 1; SELECT 2");
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.stmts.len);
}

test "split with scanner single statement" {
    var result = try splitWithScanner(std.testing.allocator, "SELECT 1");
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.stmts.len);
}

test "split with scanner empty input" {
    const result = splitWithScanner(std.testing.allocator, "");
    try std.testing.expectError(error.EmptyInput, result);
}

test "split with parser" {
    var result = try splitWithParser(std.testing.allocator, "SELECT 1; SELECT 2");
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.stmts.len);
}

test "split with parser single statement" {
    var result = try splitWithParser(std.testing.allocator, "SELECT 1");
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.stmts.len);
}

test "split with parser empty input" {
    const result = splitWithParser(std.testing.allocator, "");
    try std.testing.expectError(error.EmptyInput, result);
}

test "parse plpgsql" {
    var result = try parsePlpgsql(std.testing.allocator, "CREATE FUNCTION test() RETURNS void AS $$ BEGIN END; $$ LANGUAGE plpgsql;");
    defer result.deinit();
    try std.testing.expect(result.parse_tree.len > 0);
}

test "parse plpgsql empty input" {
    const result = parsePlpgsql(std.testing.allocator, "");
    try std.testing.expectError(error.EmptyInput, result);
}

test "is utility stmt" {
    try std.testing.expect(try isUtilityStmt("SET work_mem = '64MB'"));
}

test "is not utility stmt" {
    try std.testing.expect(!try isUtilityStmt("SELECT 1"));
}

test "is utility stmt empty input" {
    const result = isUtilityStmt("");
    try std.testing.expectError(error.EmptyInput, result);
}

test "parse protobuf" {
    var result = try parseProtobuf(std.testing.allocator, "SELECT 1");
    defer result.deinit();
    try std.testing.expect(result.parse_tree.stmts.items.len > 0);
}

test "scan protobuf" {
    var result = try scanProtobuf(std.testing.allocator, "SELECT update AS left FROM between");
    defer result.deinit();
    try std.testing.expect(result.scan_tree.tokens.items.len > 0);
}
