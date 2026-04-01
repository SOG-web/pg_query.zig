const std = @import("std");

const generated_mod = @import("generated_result.zig");
const query_result = @import("query_result.zig");
const QueryParseResult = query_result.ParseResult;
const root = @import("root.zig");
const Allocator = root.Allocator;
const ApiError = root.ApiError;
const ErrorKind = root.ErrorKind;
const Fingerprint = root.Fingerprint;
const NodeRef = root.NodeRef;
const OwnedString = root.OwnedString;
const ParsedResult = root.ParsedResult;
const ParseResult = root.ParseResult;
const PlpgsqlParseResult = root.PlpgsqlParseResult;
const ProtobufParseResult = root.ProtobufParseResult;
const QueryError = root.QueryError;
const RawParseResult = root.RawParseResult;
const RawScanResult = root.RawScanResult;
const RawScanToken = root.RawScanToken;
const ScanResult = root.ScanResult;
const SplitResult = root.SplitResult;
const SplitStmt = root.SplitStmt;
const SummaryParseResult = root.SummaryParseResult;
const Outcome = root.Outcome;
const c = root.c;
const pg_version_num = root.pg_version_num;
const scan_mod = @import("scan_result.zig");
const ScannedResult = scan_mod.ScanResult;
const summary_mod = @import("summary_result.zig");
const SummaryResult = summary_mod.SummaryResult;

pub fn parse(allocator: Allocator, sql: []const u8) ApiError!Outcome(ParsedResult) {
    return parseOpts(allocator, sql, 0);
}

pub fn parseGenerated(allocator: Allocator, sql: []const u8) ApiError!Outcome(generated_mod.ParsedResult) {
    return parseGeneratedOpts(allocator, sql, 0);
}

pub fn parseGeneratedOpts(
    allocator: Allocator,
    sql: []const u8,
    parser_options: c_int,
) ApiError!Outcome(generated_mod.ParsedResult) {
    const protobuf_result = try parseProtobufOpts(allocator, sql, parser_options);
    switch (protobuf_result) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            defer {
                var owned = value;
                owned.deinit();
            }
            return decodeGeneratedParseTree(allocator, value.parse_tree, value.stderr_buffer);
        },
    }
}

pub fn parseOpts(allocator: Allocator, sql: []const u8, parser_options: c_int) ApiError!Outcome(ParsedResult) {
    const protobuf_result = try parseProtobufOpts(allocator, sql, parser_options);
    switch (protobuf_result) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            defer {
                var owned = value;
                owned.deinit();
            }
            const unpacked = c.pg_query__parse_result__unpack(null, value.parse_tree.len, value.parse_tree.ptr);
            if (unpacked == null) {
                return .{ .err = .{
                    .allocator = allocator,
                    .kind = .parse,
                    .message = try allocator.dupe(u8, "failed to unpack protobuf parse tree"),
                    .funcname = null,
                    .filename = null,
                    .lineno = 0,
                    .cursorpos = 0,
                    .context = null,
                } };
            }

            return .{ .ok = .{
                .allocator = allocator,
                .protobuf = unpacked,
                .stderr_buffer = if (value.stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
            } };
        },
    }
}

pub fn parseDetailed(allocator: Allocator, sql: []const u8) ApiError!Outcome(QueryParseResult) {
    return parseDetailedOpts(allocator, sql, 0);
}

pub fn parseDetailedOpts(allocator: Allocator, sql: []const u8, parser_options: c_int) ApiError!Outcome(QueryParseResult) {
    var parsed = try parseGeneratedOpts(allocator, sql, parser_options);
    errdefer parsed.deinit();

    switch (parsed) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            var parsed_ok = value;
            var summarized = try summaryDetailed(allocator, sql, parser_options, -1);
            errdefer summarized.deinit();

            switch (summarized) {
                .err => |err| {
                    parsed_ok.deinit();
                    return .{ .err = err };
                },
                .ok => |summary_result| return .{ .ok = .{
                    .allocator = allocator,
                    .source_sql = try allocator.dupe(u8, sql),
                    .parsed = parsed_ok,
                    .summary = summary_result,
                } },
            }
        },
    }
}

pub fn parseViaRawDetailed(allocator: Allocator, sql: []const u8) ApiError!Outcome(QueryParseResult) {
    return parseViaRawDetailedOpts(allocator, sql, 0);
}

pub fn parseViaRawDetailedOpts(allocator: Allocator, sql: []const u8, parser_options: c_int) ApiError!Outcome(QueryParseResult) {
    var parsed = try parseViaRawToGeneratedOpts(allocator, sql, parser_options);
    errdefer parsed.deinit();

    switch (parsed) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            var parsed_ok = value;
            var summarized = try summaryDetailed(allocator, sql, parser_options, -1);
            errdefer summarized.deinit();

            switch (summarized) {
                .err => |err| {
                    parsed_ok.deinit();
                    return .{ .err = err };
                },
                .ok => |summary_result| {
                    return .{ .ok = .{
                        .allocator = allocator,
                        .source_sql = try allocator.dupe(u8, sql),
                        .parsed = parsed_ok,
                        .summary = summary_result,
                    } };
                },
            }
        },
    }
}

pub fn normalize(allocator: Allocator, sql: []const u8) ApiError!Outcome(OwnedString) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_normalize(input.ptr);
    defer c.pg_query_free_normalize_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .normalize, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .value = try dupCString(allocator, result.normalized_query),
    } };
}

pub fn normalizeUtility(allocator: Allocator, sql: []const u8) ApiError!Outcome(OwnedString) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_normalize_utility(input.ptr);
    defer c.pg_query_free_normalize_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .normalize, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .value = try dupCString(allocator, result.normalized_query),
    } };
}

pub fn parseJson(allocator: Allocator, sql: []const u8) ApiError!Outcome(ParseResult) {
    return parseJsonOpts(allocator, sql, 0);
}

pub fn parseJsonOpts(allocator: Allocator, sql: []const u8, parser_options: c_int) ApiError!Outcome(ParseResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_parse_opts(input.ptr, parser_options);
    defer c.pg_query_free_parse_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .parse, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .parse_tree = try dupCString(allocator, result.parse_tree),
        .stderr_buffer = try dupNullableCString(allocator, result.stderr_buffer),
    } };
}

pub fn parseProtobuf(allocator: Allocator, sql: []const u8) ApiError!Outcome(ProtobufParseResult) {
    return parseProtobufOpts(allocator, sql, 0);
}

pub fn parseProtobufOpts(
    allocator: Allocator,
    sql: []const u8,
    parser_options: c_int,
) ApiError!Outcome(ProtobufParseResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_parse_protobuf_opts(input.ptr, parser_options);
    defer c.pg_query_free_protobuf_parse_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .parse, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .parse_tree = try allocator.dupe(u8, result.parse_tree.data[0..result.parse_tree.len]),
        .stderr_buffer = try dupNullableCString(allocator, result.stderr_buffer),
    } };
}

pub fn parsePlpgsql(allocator: Allocator, sql: []const u8) ApiError!Outcome(PlpgsqlParseResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_parse_plpgsql(input.ptr);
    defer c.pg_query_free_plpgsql_parse_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .plpgsql, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .functions_json = try dupCString(allocator, result.plpgsql_funcs),
    } };
}

pub fn fingerprint(allocator: Allocator, sql: []const u8) ApiError!Outcome(Fingerprint) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_fingerprint(input.ptr);
    return fingerprintFromCResult(allocator, result);
}

pub fn scan(allocator: Allocator, sql: []const u8) ApiError!Outcome(ScanResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_scan(input.ptr);
    defer c.pg_query_free_scan_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .scan, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .protobuf = try allocator.dupe(u8, result.pbuf.data[0..result.pbuf.len]),
        .stderr_buffer = try dupNullableCString(allocator, result.stderr_buffer),
    } };
}

pub fn scanGenerated(allocator: Allocator, sql: []const u8) ApiError!Outcome(generated_mod.ScanResult) {
    const scanned = try scan(allocator, sql);
    switch (scanned) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            defer {
                var owned = value;
                owned.deinit();
            }
            var reader: std.Io.Reader = .fixed(value.protobuf);
            var decoded = root.pb.ScanResult.decode(&reader, allocator) catch |err| {
                return .{ .err = .{
                    .allocator = allocator,
                    .kind = .scan,
                    .message = try std.fmt.allocPrint(allocator, "failed to decode generated scan result: {s}", .{@errorName(err)}),
                    .funcname = null,
                    .filename = null,
                    .lineno = 0,
                    .cursorpos = 0,
                    .context = null,
                } };
            };
            errdefer decoded.deinit(allocator);

            return .{ .ok = .{
                .allocator = allocator,
                .protobuf = decoded,
                .stderr_buffer = if (value.stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
            } };
        },
    }
}

pub fn scanDetailed(allocator: Allocator, sql: []const u8) ApiError!Outcome(ScannedResult) {
    const scanned = try scanGenerated(allocator, sql);
    switch (scanned) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            defer {
                var owned = value;
                owned.deinit();
            }
            return .{ .ok = try scan_mod.fromGenerated(allocator, &value.protobuf, value.stderr_buffer) };
        },
    }
}

pub fn splitWithParser(allocator: Allocator, sql: []const u8) ApiError!Outcome(SplitResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_split_with_parser(input.ptr);
    return splitFromCResult(allocator, result);
}

pub fn splitWithScanner(allocator: Allocator, sql: []const u8) ApiError!Outcome(SplitResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_split_with_scanner(input.ptr);
    return splitFromCResult(allocator, result);
}

pub fn summary(
    allocator: Allocator,
    sql: []const u8,
    parser_options: c_int,
    truncate_limit: c_int,
) ApiError!Outcome(SummaryParseResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_summary(input.ptr, parser_options, truncate_limit);
    defer c.pg_query_free_summary_parse_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .summary, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .summary = try allocator.dupe(u8, result.summary.data[0..result.summary.len]),
        .stderr_buffer = try dupNullableCString(allocator, result.stderr_buffer),
    } };
}

pub fn summaryDetailed(
    allocator: Allocator,
    sql: []const u8,
    parser_options: c_int,
    truncate_limit: c_int,
) ApiError!Outcome(SummaryResult) {
    const summarized = try summary(allocator, sql, parser_options, truncate_limit);
    switch (summarized) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            defer {
                var owned = value;
                owned.deinit();
            }
            var reader: std.Io.Reader = .fixed(value.summary);
            var decoded = root.pb.SummaryResult.decode(&reader, allocator) catch |err| {
                return .{ .err = .{
                    .allocator = allocator,
                    .kind = .summary,
                    .message = try std.fmt.allocPrint(allocator, "failed to decode generated summary: {s}", .{@errorName(err)}),
                    .funcname = null,
                    .filename = null,
                    .lineno = 0,
                    .cursorpos = 0,
                    .context = null,
                } };
            };
            defer decoded.deinit(allocator);

            return .{ .ok = try summary_mod.fromGenerated(allocator, &decoded, value.stderr_buffer) };
        },
    }
}

pub fn parseRaw(allocator: Allocator, sql: []const u8) ApiError!Outcome(RawParseResult) {
    return parseRawOpts(allocator, sql, 0);
}

pub fn parseViaRawToGenerated(allocator: Allocator, sql: []const u8) ApiError!Outcome(generated_mod.GeneratedParsedResult) {
    return parseViaRawToGeneratedOpts(allocator, sql, 0);
}

pub fn parseRawOpts(allocator: Allocator, sql: []const u8, parser_options: c_int) ApiError!Outcome(RawParseResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_parse_raw_opts(input.ptr, parser_options);
    if (result.@"error" != null) {
        defer c.pg_query_free_raw_parse_result(result);
        return .{ .err = try copyQueryError(allocator, .parse, result.@"error") };
    }

    c.pg_query_free_raw_parse_result(result);
    return .{ .ok = .{
        .allocator = allocator,
        .sql = try allocator.dupe(u8, sql),
        .parser_options = parser_options,
    } };
}

pub fn parseViaRawToGeneratedOpts(
    allocator: Allocator,
    sql: []const u8,
    parser_options: c_int,
) ApiError!Outcome(generated_mod.GeneratedParsedResult) {
    const raw = try parseRawOpts(allocator, sql, parser_options);
    switch (raw) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            defer {
                var owned = value;
                owned.deinit();
            }

            const input = try dupeZ(allocator, value.sql);
            defer allocator.free(input);

            const raw_result = c.pg_query_parse_raw_opts(input.ptr, value.parser_options);
            defer c.pg_query_free_raw_parse_result(raw_result);

            if (raw_result.@"error" != null) {
                return .{ .err = try copyQueryError(allocator, .parse, raw_result.@"error") };
            }

            const result = c.pg_query_protobuf_from_raw_parse_result(raw_result);
            defer c.pg_query_free_protobuf_parse_result(result);

            if (result.@"error" != null) {
                return .{ .err = try copyQueryError(allocator, .parse, result.@"error") };
            }

            return decodeGeneratedParseTree(
                allocator,
                result.parse_tree.data[0..result.parse_tree.len],
                if (result.stderr_buffer != null) std.mem.span(result.stderr_buffer) else null,
            );
        },
    }
}

pub fn scanRaw(allocator: Allocator, sql: []const u8) ApiError!Outcome(RawScanResult) {
    const input = try dupeZ(allocator, sql);
    defer allocator.free(input);

    const result = c.pg_query_scan_raw(input.ptr);
    defer c.pg_query_free_raw_scan_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .scan, result.@"error") };
    }

    const tokens = try allocator.alloc(RawScanToken, result.n_tokens);
    errdefer allocator.free(tokens);

    for (tokens, 0..) |*token, index| {
        const source = result.tokens[index];
        token.* = .{
            .start = source.start,
            .end = source.end,
            .token = source.token,
            .keyword_kind = source.keyword_kind,
        };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .tokens = tokens,
        .stderr_buffer = try dupNullableCString(allocator, result.stderr_buffer),
    } };
}

pub fn scanRawDetailed(allocator: Allocator, sql: []const u8) ApiError!Outcome(ScannedResult) {
    const scanned = try scanRaw(allocator, sql);
    switch (scanned) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            defer {
                var owned = value;
                owned.deinit();
            }
            const tokens = try allocator.alloc(scan_mod.ScanToken, value.tokens.len);
            errdefer allocator.free(tokens);

            for (tokens, value.tokens) |*dest, source| {
                dest.* = .{
                    .start = source.start,
                    .end = source.end,
                    .token = source.token,
                    .keyword_kind = source.keyword_kind,
                };
            }

            return .{ .ok = .{
                .allocator = allocator,
                .tokens = tokens,
                .stderr_buffer = if (value.stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
            } };
        },
    }
}

pub fn scanRawGenerated(allocator: Allocator, sql: []const u8) ApiError!Outcome(generated_mod.ScanResult) {
    const scanned = try scanRaw(allocator, sql);
    switch (scanned) {
        .err => |err| return .{ .err = err },
        .ok => |value| {
            defer {
                var owned = value;
                owned.deinit();
            }
            return .{ .ok = try generated_mod.fromRawScan(allocator, pg_version_num, value.tokens, value.stderr_buffer) };
        },
    }
}

pub fn deparseProtobuf(allocator: Allocator, protobuf: []const u8) ApiError!Outcome(OwnedString) {
    const input = try allocator.dupe(u8, protobuf);
    defer allocator.free(input);

    const pbuf = c.PgQueryProtobuf{
        .len = input.len,
        .data = @ptrCast(input.ptr),
    };
    const result = c.pg_query_deparse_protobuf(pbuf);
    return deparseFromCResult(allocator, result);
}

pub fn deparseNodeRef(allocator: Allocator, node: NodeRef) ApiError!Outcome(OwnedString) {
    var wrapped_node: c.PgQuery__Node = std.mem.zeroInit(c.PgQuery__Node, .{});
    c.pg_query__node__init(&wrapped_node);

    switch (node) {
        inline else => |payload, tag| {
            _ = tag;
            const field_name = comptime nodeUnionFieldName(@TypeOf(payload));
            wrapped_node.node_case = @field(c, "PG_QUERY__NODE__NODE_" ++ nodeEnumCaseName(field_name));
            @field(wrapped_node.unnamed_0, field_name) = @ptrCast(@constCast(payload));
        },
    }

    var raw_stmt: c.PgQuery__RawStmt = std.mem.zeroInit(c.PgQuery__RawStmt, .{});
    c.pg_query__raw_stmt__init(&raw_stmt);
    raw_stmt.stmt = &wrapped_node;

    var stmts = [_]?*c.PgQuery__RawStmt{&raw_stmt};
    var parse_result: c.PgQuery__ParseResult = std.mem.zeroInit(c.PgQuery__ParseResult, .{});
    c.pg_query__parse_result__init(&parse_result);
    parse_result.version = pg_version_num;
    parse_result.n_stmts = 1;
    parse_result.stmts = @ptrCast(&stmts);

    return deparsePackedParseResult(allocator, &parse_result);
}

pub fn deparseRaw(allocator: Allocator, raw: *const RawParseResult) ApiError!Outcome(OwnedString) {
    const input = try dupeZ(allocator, raw.sql);
    defer allocator.free(input);

    const raw_result = c.pg_query_parse_raw_opts(input.ptr, raw.parser_options);
    defer c.pg_query_free_raw_parse_result(raw_result);

    if (raw_result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .parse, raw_result.@"error") };
    }

    const result = c.pg_query_deparse_raw(raw_result);
    return deparseFromCResult(allocator, result);
}

pub fn fingerprintRaw(allocator: Allocator, raw: *const RawParseResult) ApiError!Outcome(Fingerprint) {
    const input = try dupeZ(allocator, raw.sql);
    defer allocator.free(input);

    const raw_result = c.pg_query_parse_raw_opts(input.ptr, raw.parser_options);
    defer c.pg_query_free_raw_parse_result(raw_result);

    if (raw_result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .parse, raw_result.@"error") };
    }

    const result = c.pg_query_fingerprint_raw(raw_result);
    return fingerprintFromCResult(allocator, result);
}

pub fn fingerprintFromCResult(
    allocator: Allocator,
    result: c.PgQueryFingerprintResult,
) ApiError!Outcome(Fingerprint) {
    defer c.pg_query_free_fingerprint_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .fingerprint, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .value = result.fingerprint,
        .hex = try dupCString(allocator, result.fingerprint_str),
        .stderr_buffer = try dupNullableCString(allocator, result.stderr_buffer),
    } };
}

pub fn deparseFromCResult(
    allocator: Allocator,
    result: c.PgQueryDeparseResult,
) ApiError!Outcome(OwnedString) {
    defer c.pg_query_free_deparse_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .deparse, result.@"error") };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .value = try dupCString(allocator, result.query),
    } };
}

pub fn deparsePackedParseResult(
    allocator: Allocator,
    parse_result: *const c.PgQuery__ParseResult,
) ApiError!Outcome(OwnedString) {
    const packed_size = c.pg_query__parse_result__get_packed_size(parse_result);
    const buffer = try allocator.alloc(u8, packed_size);
    defer allocator.free(buffer);

    _ = c.pg_query__parse_result__pack(parse_result, buffer.ptr);
    return deparseProtobuf(allocator, buffer);
}

pub fn deparseGeneratedParseResult(
    allocator: Allocator,
    parse_result: *const root.pb.ParseResult,
) ApiError!Outcome(OwnedString) {
    var writer: std.Io.Writer.Allocating = .init(allocator);
    defer writer.deinit();

    parse_result.encode(&writer.writer, allocator) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .err = .{
            .allocator = allocator,
            .kind = .deparse,
            .message = try std.fmt.allocPrint(allocator, "failed to encode generated parse result: {s}", .{@errorName(err)}),
            .funcname = null,
            .filename = null,
            .lineno = 0,
            .cursorpos = 0,
            .context = null,
        } },
    };
    return deparseProtobuf(allocator, writer.written());
}

fn splitFromCResult(
    allocator: Allocator,
    result: c.PgQuerySplitResult,
) ApiError!Outcome(SplitResult) {
    defer c.pg_query_free_split_result(result);

    if (result.@"error" != null) {
        return .{ .err = try copyQueryError(allocator, .split, result.@"error") };
    }

    const count: usize = @intCast(result.n_stmts);
    const stmts = try allocator.alloc(SplitStmt, count);
    errdefer allocator.free(stmts);

    for (stmts, 0..) |*stmt, index| {
        const source = result.stmts[index].*;
        stmt.* = .{
            .stmt_location = source.stmt_location,
            .stmt_len = source.stmt_len,
        };
    }

    return .{ .ok = .{
        .allocator = allocator,
        .stmts = stmts,
        .stderr_buffer = try dupNullableCString(allocator, result.stderr_buffer),
    } };
}

fn copyQueryError(
    allocator: Allocator,
    kind: ErrorKind,
    source: ?*c.PgQueryError,
) ApiError!QueryError {
    const err_ptr = source orelse unreachable;
    return .{
        .allocator = allocator,
        .kind = kind,
        .message = try dupCString(allocator, err_ptr.message),
        .funcname = try dupNullableCString(allocator, err_ptr.funcname),
        .filename = try dupNullableCString(allocator, err_ptr.filename),
        .lineno = err_ptr.lineno,
        .cursorpos = err_ptr.cursorpos,
        .context = try dupNullableCString(allocator, err_ptr.context),
    };
}

fn decodeGeneratedParseTree(
    allocator: Allocator,
    bytes: []const u8,
    stderr_buffer: ?[]const u8,
) ApiError!Outcome(generated_mod.ParsedResult) {
    var reader: std.Io.Reader = .fixed(bytes);
    var decoded = root.pb.ParseResult.decode(&reader, allocator) catch |err| {
        return .{ .err = .{
            .allocator = allocator,
            .kind = .parse,
            .message = try std.fmt.allocPrint(allocator, "failed to decode generated parse tree: {s}", .{@errorName(err)}),
            .funcname = null,
            .filename = null,
            .lineno = 0,
            .cursorpos = 0,
            .context = null,
        } };
    };
    errdefer decoded.deinit(allocator);

    return .{ .ok = .{
        .allocator = allocator,
        .protobuf = decoded,
        .stderr_buffer = if (stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
    } };
}

fn packGeneratedParseResultToC(allocator: Allocator, parse_result: *const root.pb.ParseResult) !*c.PgQuery__ParseResult {
    var writer: std.Io.Writer.Allocating = .init(allocator);
    defer writer.deinit();

    try parse_result.encode(&writer.writer, allocator);
    const packed_bytes = writer.written();
    const unpacked = c.pg_query__parse_result__unpack(null, packed_bytes.len, packed_bytes.ptr);
    if (unpacked == null) return error.FailedToPackGeneratedParseTree;
    return unpacked;
}

fn dupeZ(allocator: Allocator, input: []const u8) ApiError![:0]u8 {
    if (std.mem.indexOfScalar(u8, input, 0) != null) return error.ContainsNulByte;
    return try allocator.dupeZ(u8, input);
}

fn dupCString(allocator: Allocator, source: [*c]u8) Allocator.Error![]u8 {
    return allocator.dupe(u8, std.mem.span(source));
}

fn dupNullableCString(allocator: Allocator, source: ?[*c]u8) Allocator.Error!?[]u8 {
    const ptr = source orelse return null;
    if (@intFromPtr(ptr) == 0) return null;
    return try allocator.dupe(u8, std.mem.span(ptr));
}

fn nodeUnionFieldName(comptime Payload: type) []const u8 {
    @setEvalBranchQuota(1_000_000);
    inline for (@typeInfo(@FieldType(c.PgQuery__Node, "unnamed_0")).@"union".fields) |field| {
        if (nodePayloadMatches(field.type, Payload)) return field.name;
    }
    @compileError("unsupported PgQuery__Node payload type: " ++ @typeName(Payload));
}

fn nodePayloadMatches(comptime a: type, comptime b: type) bool {
    const a_info = @typeInfo(a);
    const b_info = @typeInfo(b);
    if (a_info != .pointer or b_info != .pointer) return a == b;

    const a_ptr = a_info.pointer;
    const b_ptr = b_info.pointer;
    return a_ptr.child == b_ptr.child;
}

fn snakeToScreamingSnake(comptime value: []const u8) []const u8 {
    comptime var buf: [256]u8 = undefined;
    comptime var len: usize = 0;
    inline for (value) |ch| {
        buf[len] = std.ascii.toUpper(ch);
        len += 1;
    }
    return buf[0..len];
}

fn nodeEnumCaseName(comptime field_name: []const u8) []const u8 {
    return snakeToScreamingSnake(sanitizeZigIdentifier(field_name));
}

fn sanitizeZigIdentifier(comptime value: []const u8) []const u8 {
    comptime var start: usize = 0;
    comptime var end: usize = value.len;

    if (std.mem.startsWith(u8, value, "@\"")) {
        start = 2;
        end -= 1;
    }

    if (end > start and value[end - 1] == '_') {
        end -= 1;
    }

    return value[start..end];
}

test "normalize wraps libpg_query" {
    const allocator = std.testing.allocator;
    var result = try normalize(allocator, "SELECT * FROM users WHERE id = 42");
    defer result.deinit();

    switch (result) {
        .ok => |value| try std.testing.expectEqualStrings("SELECT * FROM users WHERE id = $1", value.value),
        .err => try std.testing.expect(false),
    }
}

test "fingerprint wraps libpg_query" {
    const allocator = std.testing.allocator;
    var result = try fingerprint(allocator, "SELECT * FROM users WHERE id = 1");
    defer result.deinit();

    switch (result) {
        .ok => |value| try std.testing.expect(value.hex.len == 16),
        .err => try std.testing.expect(false),
    }
}

test "parse json returns parse tree text" {
    const allocator = std.testing.allocator;
    var result = try parseJson(allocator, "SELECT 1");
    defer result.deinit();

    switch (result) {
        .ok => |value| {
            try std.testing.expect(std.mem.indexOf(u8, value.parse_tree, "\"SelectStmt\"") != null);
        },
        .err => try std.testing.expect(false),
    }
}

test "split with parser returns statement slices" {
    const allocator = std.testing.allocator;
    const sql = "SELECT 1; SELECT 2";
    var result = try splitWithParser(allocator, sql);
    defer result.deinit();

    switch (result) {
        .ok => |value| {
            try std.testing.expectEqual(@as(usize, 2), value.stmts.len);
            try std.testing.expectEqualStrings("SELECT 1", value.stmts[0].slice(sql));
            try std.testing.expectEqualStrings(" SELECT 2", value.stmts[1].slice(sql));
        },
        .err => try std.testing.expect(false),
    }
}

test "raw parse can deparse" {
    const allocator = std.testing.allocator;
    var parsed = try parseRaw(allocator, "SELECT * FROM users");
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            var deparsed = try value.deparse(allocator);
            defer deparsed.deinit();

            switch (deparsed) {
                .ok => |sql| try std.testing.expectEqualStrings("SELECT * FROM users", sql.value),
                .err => try std.testing.expect(false),
            }
        },
        .err => try std.testing.expect(false),
    }
}

test "typed parse returns top level node refs" {
    const allocator = std.testing.allocator;
    var parsed = try parse(allocator, "SELECT 1; INSERT INTO users (id) VALUES (1)");
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            try std.testing.expectEqual(@as(usize, 2), value.stmtCount());
            try std.testing.expect(value.stmtNode(0) != null);
            try std.testing.expect(value.stmtNode(1) != null);
            try std.testing.expect(value.stmtNode(2) == null);
            try std.testing.expect(std.meta.activeTag(value.stmtNode(0).?) == .SelectStmt);
            try std.testing.expect(std.meta.activeTag(value.stmtNode(1).?) == .InsertStmt);
        },
        .err => try std.testing.expect(false),
    }
}

test "generated parse returns zig-native protobuf tree" {
    const allocator = std.testing.allocator;
    var parsed = try parseGenerated(allocator, "SELECT 1; INSERT INTO users (id) VALUES (1)");
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            try std.testing.expectEqual(@as(usize, 2), value.stmtCount());
            try std.testing.expect(value.stmtNode(0) != null);
            try std.testing.expect(value.stmtNode(1) != null);
            try std.testing.expect(value.stmtNode(2) == null);
            try std.testing.expect(value.stmtNode(0).?.node != null);
            try std.testing.expect(value.stmtNode(1).?.node != null);

            var deparsed = try value.deparse(allocator);
            defer deparsed.deinit();

            switch (deparsed) {
                .ok => |sql| try std.testing.expectEqualStrings("SELECT 1; INSERT INTO users (id) VALUES (1)", sql.value),
                .err => try std.testing.expect(false),
            }
        },
        .err => try std.testing.expect(false),
    }
}

test "parseViaRawToGenerated returns zig-native protobuf tree" {
    const allocator = std.testing.allocator;
    var parsed = try parseViaRawToGenerated(allocator, "SELECT 1; INSERT INTO users (id) VALUES (1)");
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            try std.testing.expectEqual(@as(usize, 2), value.stmtCount());
            try std.testing.expect(value.stmtNode(0) != null);
            try std.testing.expect(value.stmtNode(1) != null);
            try std.testing.expect(value.stmtNode(0).?.node != null);
            try std.testing.expect(value.stmtNode(1).?.node != null);
        },
        .err => try std.testing.expect(false),
    }
}

test "generated parse nodes traverses statement tree" {
    const allocator = std.testing.allocator;
    var parsed = try parseGenerated(allocator, "SELECT x FROM users WHERE id = 1");
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            const nodes = try value.nodes(allocator);
            defer allocator.free(nodes);

            try std.testing.expect(nodes.len >= 3);
            try std.testing.expect(std.meta.activeTag(nodes[0].node) == .select_stmt);
        },
        .err => try std.testing.expect(false),
    }
}

test "generated node ref supports owned conversion and direct deparse" {
    const allocator = std.testing.allocator;
    var parsed = try parseViaRawToGenerated(allocator, "SELECT * FROM users");
    defer parsed.deinit();

    switch (parsed) {
        .err => try std.testing.expect(false),
        .ok => |value| {
            const visited = try value.nodes(allocator);
            defer allocator.free(visited);
            try std.testing.expect(visited.len > 0);

            const owned = visited[0].node.toOwnedNode();
            try std.testing.expect(owned.node != null);

            var sql = try visited[0].node.deparseDirect(allocator);
            defer sql.deinit();
            switch (sql) {
                .ok => |text| try std.testing.expect(text.value.len > 0),
                .err => try std.testing.expect(false),
            }
        },
    }
}

test "generated node mut supports owned conversion and direct deparse" {
    const allocator = std.testing.allocator;
    var parsed = try parseViaRawToGenerated(allocator, "SELECT * FROM users");
    defer parsed.deinit();

    switch (parsed) {
        .err => try std.testing.expect(false),
        .ok => |*value| {
            const visited = try value.nodesMut(allocator);
            defer allocator.free(visited);
            try std.testing.expect(visited.len > 0);

            const owned = visited[0].node.toOwnedNode();
            try std.testing.expect(owned.node != null);

            var sql = try visited[0].node.deparseDirect(allocator);
            defer sql.deinit();
            switch (sql) {
                .ok => |text| try std.testing.expect(text.value.len > 0),
                .err => try std.testing.expect(false),
            }
        },
    }
}

test "generated parse result helper module exposes direct operations" {
    const allocator = std.testing.allocator;
    var parsed = try parseViaRawToGenerated(allocator, "INSERT INTO x (a, b, c, d, e, f) VALUES ($1)");
    defer parsed.deinit();

    switch (parsed) {
        .err => try std.testing.expect(false),
        .ok => |*value| {
            const stmt_types = try root.parse_result.statementTypes(allocator, &value.protobuf);
            defer allocator.free(stmt_types);
            try std.testing.expectEqual(@as(usize, 1), stmt_types.len);
            try std.testing.expectEqualStrings("InsertStmt", stmt_types[0]);

            const visited = try root.parse_result.nodes(allocator, &value.protobuf);
            defer allocator.free(visited);
            try std.testing.expect(visited.len > 0);

            const visited_mut = try root.parse_result.nodesMut(allocator, &value.protobuf);
            defer allocator.free(visited_mut);
            try std.testing.expect(visited_mut.len > 0);

            var raw_sql = try root.parse_result.deparseDirect(allocator, &value.protobuf);
            defer raw_sql.deinit();
            switch (raw_sql) {
                .ok => |text| try std.testing.expect(text.value.len > 0),
                .err => try std.testing.expect(false),
            }

            var truncated = try root.parse_result.truncate(allocator, &value.protobuf, 32);
            defer truncated.deinit();
            switch (truncated) {
                .ok => |text| try std.testing.expect(text.value.len <= 32),
                .err => try std.testing.expect(false),
            }
        },
    }
}

test "generated typed stmt node helpers expose exhaustive unions" {
    const allocator = std.testing.allocator;
    var parsed = try parseViaRawToGenerated(allocator, "SELECT * FROM users");
    defer parsed.deinit();

    switch (parsed) {
        .err => try std.testing.expect(false),
        .ok => |*value| {
            const typed = value.stmtNodeTyped(0) orelse return error.TestUnexpectedResult;
            try std.testing.expect(std.meta.activeTag(typed) == .select_stmt);

            var raw_sql = try typed.deparseDirect(allocator);
            defer raw_sql.deinit();
            switch (raw_sql) {
                .ok => |text| try std.testing.expect(text.value.len > 0),
                .err => try std.testing.expect(false),
            }

            const typed_mut = value.stmtNodeTypedMut(0) orelse return error.TestUnexpectedResult;
            try std.testing.expect(std.meta.activeTag(typed_mut) == .select_stmt);
        },
    }
}

test "router classifies simple read and write statements" {
    const allocator = std.testing.allocator;

    var read = try root.router.analyzeSql(allocator, "SELECT * FROM users");
    defer read.deinit();
    switch (read) {
        .ok => |analysis| {
            try std.testing.expectEqual(root.router.Decision.replica, analysis.decision);
            try std.testing.expectEqual(root.router.Category.read, analysis.category);
        },
        .err => try std.testing.expect(false),
    }

    var write = try root.router.analyzeSql(allocator, "INSERT INTO users (id) VALUES (1)");
    defer write.deinit();
    switch (write) {
        .ok => |analysis| {
            try std.testing.expectEqual(root.router.Decision.primary, analysis.decision);
            try std.testing.expectEqual(root.router.Category.write, analysis.category);
        },
        .err => try std.testing.expect(false),
    }
}

test "router marks locking reads and transaction control as primary" {
    const allocator = std.testing.allocator;

    var locking = try root.router.analyzeSql(allocator, "SELECT * FROM users FOR UPDATE");
    defer locking.deinit();
    switch (locking) {
        .ok => |analysis| {
            try std.testing.expectEqual(root.router.Decision.primary, analysis.decision);
            try std.testing.expect(analysis.has_locking_read);
        },
        .err => try std.testing.expect(false),
    }

    var tx = try root.router.analyzeSql(allocator, "BEGIN");
    defer tx.deinit();
    switch (tx) {
        .ok => |analysis| {
            try std.testing.expectEqual(root.router.Decision.primary, analysis.decision);
            try std.testing.expectEqual(root.router.Category.transaction_control, analysis.category);
        },
        .err => try std.testing.expect(false),
    }
}

test "node ref can deparse" {
    const allocator = std.testing.allocator;
    var parsed = try parse(allocator, "SELECT x FROM users");
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            const node = value.stmtNode(0) orelse return error.TestUnexpectedResult;
            var deparsed = try node.deparse(allocator);
            defer deparsed.deinit();

            switch (deparsed) {
                .ok => |sql| try std.testing.expectEqualStrings("SELECT x FROM users", sql.value),
                .err => try std.testing.expect(false),
            }
        },
        .err => try std.testing.expect(false),
    }
}

test "summaryDetailed exposes semantic summary data" {
    const allocator = std.testing.allocator;
    var summarized = try summaryDetailed(allocator, "SELECT * FROM contacts", 0, -1);
    defer summarized.deinit();

    switch (summarized) {
        .ok => |value| {
            const tables = try value.tables(allocator);
            defer allocator.free(tables);
            try std.testing.expectEqual(@as(usize, 1), tables.len);
            try std.testing.expectEqualStrings("contacts", tables[0]);
            try std.testing.expect(value.statementTypes().len >= 1);
            try std.testing.expectEqualStrings("SelectStmt", value.statementTypes()[0]);
        },
        .err => try std.testing.expect(false),
    }
}

test "parseDetailed exposes truncate and semantic helpers" {
    const allocator = std.testing.allocator;
    const sql = "INSERT INTO x (a, b, c, d, e, f) VALUES ($1)";
    var parsed = try parseDetailed(allocator, sql);
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            const tables = try value.tables(allocator);
            defer allocator.free(tables);
            try std.testing.expectEqual(@as(usize, 1), tables.len);
            try std.testing.expectEqualStrings("x", tables[0]);

            var truncated = try value.truncate(allocator, 32);
            defer truncated.deinit();
            switch (truncated) {
                .ok => |truncated_sql| try std.testing.expect(truncated_sql.value.len <= 32),
                .err => try std.testing.expect(false),
            }
        },
        .err => try std.testing.expect(false),
    }
}

test "scanDetailed exposes typed tokens" {
    const allocator = std.testing.allocator;
    var scanned = try scanDetailed(allocator, "SELECT * FROM users");
    defer scanned.deinit();

    switch (scanned) {
        .ok => |value| {
            try std.testing.expect(value.tokens.len > 0);
            try std.testing.expectEqual(@as(c_int, 0), value.tokens[0].start);
            try std.testing.expectEqual(@as(c_int, 6), value.tokens[0].end);
        },
        .err => try std.testing.expect(false),
    }
}

test "scanGenerated returns zig-native protobuf tokens" {
    const allocator = std.testing.allocator;
    var scanned = try scanGenerated(allocator, "SELECT * FROM users");
    defer scanned.deinit();

    switch (scanned) {
        .ok => |value| {
            try std.testing.expect(value.tokenCount() > 0);
            try std.testing.expectEqual(@as(i32, 0), value.protobuf.tokens.items[0].start);
            try std.testing.expectEqual(@as(i32, 6), value.protobuf.tokens.items[0].end);
        },
        .err => try std.testing.expect(false),
    }
}

test "scanRawGenerated matches scanGenerated" {
    const allocator = std.testing.allocator;
    const sql = "SELECT id, name FROM users WHERE active = true";

    var raw_scanned = try scanRawGenerated(allocator, sql);
    defer raw_scanned.deinit();

    var scanned = try scanGenerated(allocator, sql);
    defer scanned.deinit();

    switch (raw_scanned) {
        .err => try std.testing.expect(false),
        .ok => |raw_value| switch (scanned) {
            .err => try std.testing.expect(false),
            .ok => |value| {
                try std.testing.expectEqual(value.protobuf.version, raw_value.protobuf.version);
                try std.testing.expectEqual(value.protobuf.tokens.items.len, raw_value.protobuf.tokens.items.len);

                for (value.protobuf.tokens.items, raw_value.protobuf.tokens.items) |token, raw_token| {
                    try std.testing.expectEqual(token.start, raw_token.start);
                    try std.testing.expectEqual(token.end, raw_token.end);
                    try std.testing.expectEqual(token.token, raw_token.token);
                    try std.testing.expectEqual(token.keyword_kind, raw_token.keyword_kind);
                }
            },
        },
    }
}

test "scanRawDetailed matches scanDetailed token count" {
    const allocator = std.testing.allocator;
    const sql = "SELECT id, name FROM users WHERE active = true";

    var detailed = try scanDetailed(allocator, sql);
    defer detailed.deinit();
    var raw_detailed = try scanRawDetailed(allocator, sql);
    defer raw_detailed.deinit();

    switch (detailed) {
        .ok => |left| switch (raw_detailed) {
            .ok => |right| try std.testing.expectEqual(left.tokens.len, right.tokens.len),
            .err => try std.testing.expect(false),
        },
        .err => try std.testing.expect(false),
    }
}

test "parseViaRawDetailed returns semantic parse result" {
    const allocator = std.testing.allocator;
    var parsed = try parseViaRawDetailed(allocator, "SELECT * FROM contacts");
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            const tables = try value.tables(allocator);
            defer allocator.free(tables);
            try std.testing.expectEqual(@as(usize, 1), tables.len);
            try std.testing.expectEqualStrings("contacts", tables[0]);
        },
        .err => try std.testing.expect(false),
    }
}

test "truncateGenerated shortens long insert" {
    const allocator = std.testing.allocator;
    var parsed = try parseViaRawToGenerated(allocator, "INSERT INTO x (a, b, c, d, e, f) VALUES ($1)");
    defer parsed.deinit();

    switch (parsed) {
        .ok => |value| {
            var truncated = try root.truncate.truncateGenerated(allocator, &value.protobuf, 32);
            defer truncated.deinit();

            switch (truncated) {
                .ok => |sql| try std.testing.expect(sql.value.len <= 32),
                .err => try std.testing.expect(false),
            }
        },
        .err => try std.testing.expect(false),
    }
}
