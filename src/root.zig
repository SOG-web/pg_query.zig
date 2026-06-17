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
pub const encodeProtobuf = pg_query.encodeProtobuf;
pub const encodeProtobufBuf = pg_query.encodeProtobufBuf;

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

test "encode protobuf round-trip simple select" {
    var parsed = try parseProtobuf(std.testing.allocator, "SELECT 1");
    defer parsed.deinit();

    const encoded = try encodeProtobuf(std.testing.allocator, &parsed.parse_tree);
    defer std.testing.allocator.free(encoded);

    try std.testing.expect(encoded.len > 0);

    var reader: std.Io.Reader = .fixed(encoded);
    var decoded = try proto.ParseResult.decode(&reader, std.testing.allocator);
    defer decoded.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), decoded.stmts.items.len);
    try std.testing.expect(decoded.stmts.items[0].stmt != null);
}

test "encode protobuf round-trip multi-statement" {
    var parsed = try parseProtobuf(std.testing.allocator, "SELECT 1; SELECT 2; SELECT 3");
    defer parsed.deinit();

    const encoded = try encodeProtobuf(std.testing.allocator, &parsed.parse_tree);
    defer std.testing.allocator.free(encoded);

    var reader: std.Io.Reader = .fixed(encoded);
    var decoded = try proto.ParseResult.decode(&reader, std.testing.allocator);
    defer decoded.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 3), decoded.stmts.items.len);
}

test "encode protobuf round-trip complex query" {
    const sql =
        \\SELECT u.id, u.name, o.total
        \\FROM users u
        \\JOIN orders o ON u.id = o.user_id
        \\WHERE u.active = true
        \\ORDER BY o.total DESC
        \\LIMIT 10
    ;
    var parsed = try parseProtobuf(std.testing.allocator, sql);
    defer parsed.deinit();

    const encoded = try encodeProtobuf(std.testing.allocator, &parsed.parse_tree);
    defer std.testing.allocator.free(encoded);

    var reader: std.Io.Reader = .fixed(encoded);
    var decoded = try proto.ParseResult.decode(&reader, std.testing.allocator);
    defer decoded.deinit(std.testing.allocator);

    try std.testing.expect(decoded.stmts.items.len > 0);
    const stmt = decoded.stmts.items[0];
    try std.testing.expect(stmt.stmt != null);
    if (stmt.stmt.?.node) |node| {
        try std.testing.expect(node == .select_stmt);
    }
}

test "encode protobuf round-trip insert" {
    var parsed = try parseProtobuf(std.testing.allocator, "INSERT INTO users (name, email) VALUES ('alice', 'alice@example.com')");
    defer parsed.deinit();

    const encoded = try encodeProtobuf(std.testing.allocator, &parsed.parse_tree);
    defer std.testing.allocator.free(encoded);

    var reader: std.Io.Reader = .fixed(encoded);
    var decoded = try proto.ParseResult.decode(&reader, std.testing.allocator);
    defer decoded.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), decoded.stmts.items.len);
    if (decoded.stmts.items[0].stmt.?.node) |node| {
        try std.testing.expect(node == .insert_stmt);
    }
}

test "encode protobuf round-trip create table" {
    var parsed = try parseProtobuf(std.testing.allocator, "CREATE TABLE posts (id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL, body TEXT)");
    defer parsed.deinit();

    const encoded = try encodeProtobuf(std.testing.allocator, &parsed.parse_tree);
    defer std.testing.allocator.free(encoded);

    var reader: std.Io.Reader = .fixed(encoded);
    var decoded = try proto.ParseResult.decode(&reader, std.testing.allocator);
    defer decoded.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), decoded.stmts.items.len);
    if (decoded.stmts.items[0].stmt.?.node) |node| {
        try std.testing.expect(node == .create_stmt);
    }
}

test "encode protobuf empty stmts" {
    var empty = proto.ParseResult{};

    const encoded = try encodeProtobuf(std.testing.allocator, &empty);
    defer std.testing.allocator.free(encoded);

    var reader: std.Io.Reader = .fixed(encoded);
    var decoded = try proto.ParseResult.decode(&reader, std.testing.allocator);
    defer decoded.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 0), decoded.stmts.items.len);
}

test "encode protobuf buf round-trip simple select" {
    var parsed = try parseProtobuf(std.testing.allocator, "SELECT 1");
    defer parsed.deinit();

    const encoded = try encodeProtobufBuf(std.testing.allocator, &parsed.parse_tree, null);
    defer std.testing.allocator.free(encoded);
    try std.testing.expect(encoded.len > 0);

    var reader: std.Io.Reader = .fixed(encoded);
    var decoded = try proto.ParseResult.decode(&reader, std.testing.allocator);
    defer decoded.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), decoded.stmts.items.len);
    try std.testing.expect(decoded.stmts.items[0].stmt != null);
}

test "encode protobuf buf custom buffer" {
    var parsed = try parseProtobuf(std.testing.allocator, "SELECT 1");
    defer parsed.deinit();

    var buf: [4096]u8 = undefined;
    const encoded = try encodeProtobufBuf(std.testing.allocator, &parsed.parse_tree, &buf);
    defer std.testing.allocator.free(encoded);
    try std.testing.expect(encoded.len > 0);

    var reader: std.Io.Reader = .fixed(encoded);
    var decoded = try proto.ParseResult.decode(&reader, std.testing.allocator);
    defer decoded.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), decoded.stmts.items.len);
}

test "encode protobuf buf insufficient space" {
    var parsed = try parseProtobuf(std.testing.allocator, "SELECT 1");
    defer parsed.deinit();

    var buf: [2]u8 = undefined;
    const result = encodeProtobufBuf(std.testing.allocator, &parsed.parse_tree, &buf);
    try std.testing.expectError(error.WriteFailed, result);
}
