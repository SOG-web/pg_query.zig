const std = @import("std");
const c = @import("c");
const proto = @import("pg_query_proto");

fn copyCString(allocator: std.mem.Allocator, ptr: [*c]const u8) ![]u8 {
    if (ptr == null) return "";
    const len = std.mem.len(ptr);
    return allocator.dupe(u8, ptr[0..len]) catch return error.MemoryAllocationFailed;
}

fn checkError(result: anytype) Error!void {
    if (result.@"error") |err| {
        std.debug.print("error: {s}\n", .{err.*.message});
        return error.ParseError;
    }
}

pub const Error = error{
    MemoryAllocationFailed,
    ParseError,
    OutOfMemory,
    EmptyInput,
};

pub const ParseResult = struct {
    parse_tree: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ParseResult) void {
        self.allocator.free(self.parse_tree);
    }
};

pub const NormalizeResult = struct {
    normalized: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *NormalizeResult) void {
        self.allocator.free(self.normalized);
    }
};

pub const FingerPrintResult = struct {
    hash: u64,
    hex: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *FingerPrintResult) void {
        self.allocator.free(self.hex);
    }
};

pub const SplitResult = struct {
    stmts: [][]const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *SplitResult) void {
        for (self.stmts) |statement| {
            self.allocator.free(statement);
        }
        self.allocator.free(self.stmts);
    }
};

pub fn parse(allocator: std.mem.Allocator, sql: []const u8) Error!ParseResult {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_parse(@ptrCast(sql.ptr));
    defer c.pg_query_free_parse_result(result);

    try checkError(&result);

    const parsed = try copyCString(allocator, result.parse_tree);
    return ParseResult{
        .parse_tree = parsed,
        .allocator = allocator,
    };
}

pub fn normalize(allocator: std.mem.Allocator, sql: []const u8) Error!NormalizeResult {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_normalize(@ptrCast(sql.ptr));
    defer c.pg_query_free_normalize_result(result);

    try checkError(&result);

    const normalized = try copyCString(allocator, result.normalized_query);
    return NormalizeResult{
        .normalized = normalized,
        .allocator = allocator,
    };
}

pub fn normalizeUtility(allocator: std.mem.Allocator, sql: []const u8) Error!NormalizeResult {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_normalize_utility(@ptrCast(sql.ptr));
    defer c.pg_query_free_normalize_result(result);

    try checkError(&result);

    const normalized = try copyCString(allocator, result.normalized_query);
    return NormalizeResult{
        .normalized = normalized,
        .allocator = allocator,
    };
}

pub fn fingerprint(allocator: std.mem.Allocator, sql: []const u8) Error!FingerPrintResult {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_fingerprint(@ptrCast(sql.ptr));
    defer c.pg_query_free_fingerprint_result(result);

    try checkError(&result);

    const hex = try copyCString(allocator, result.fingerprint_str);
    return FingerPrintResult{
        .hash = result.fingerprint,
        .hex = hex,
        .allocator = allocator,
    };
}

pub fn splitWithScanner(allocator: std.mem.Allocator, sql: []const u8) Error!SplitResult {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_split_with_scanner(@ptrCast(sql.ptr));
    defer c.pg_query_free_split_result(result);

    try checkError(&result);

    const n_stmts: usize = @intCast(result.n_stmts);
    var stmts = try allocator.alloc([]const u8, n_stmts);
    errdefer {
        for (stmts) |stmt| {
            allocator.free(stmt);
        }
        allocator.free(stmts);
    }

    for (0..@intCast(result.n_stmts)) |i| {
        const loc = result.stmts[i].*.stmt_location;
        const len = result.stmts[i].*.stmt_len;
        stmts[i] = try allocator.dupe(u8, sql[@intCast(loc)..@intCast(loc + len)]);
    }

    return SplitResult{
        .stmts = stmts,
        .allocator = allocator,
    };
}

pub fn splitWithParser(allocator: std.mem.Allocator, sql: []const u8) Error!SplitResult {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_split_with_parser(@ptrCast(sql.ptr));
    defer c.pg_query_free_split_result(result);

    try checkError(&result);

    const n_stmts: usize = @intCast(result.n_stmts);
    var stmts = try allocator.alloc([]const u8, n_stmts);
    errdefer {
        for (stmts) |stmt| {
            allocator.free(stmt);
        }
        allocator.free(stmts);
    }

    for (0..@intCast(result.n_stmts)) |i| {
        const loc = result.stmts[i].*.stmt_location;
        const len = result.stmts[i].*.stmt_len;
        stmts[i] = try allocator.dupe(u8, sql[@intCast(loc)..@intCast(loc + len)]);
    }

    return SplitResult{
        .stmts = stmts,
        .allocator = allocator,
    };
}

pub fn parsePlpgsql(allocator: std.mem.Allocator, sql: []const u8) Error!ParseResult {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_parse_plpgsql(@ptrCast(sql.ptr));
    defer c.pg_query_free_plpgsql_parse_result(result);

    try checkError(&result);

    const parsed = try copyCString(allocator, result.plpgsql_funcs);

    return ParseResult{
        .parse_tree = parsed,
        .allocator = allocator,
    };
}

pub fn isUtilityStmt(sql: []const u8) Error!bool {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_is_utility_stmt(@ptrCast(sql.ptr));
    defer c.pg_query_free_is_utility_result(result);

    try checkError(&result);

    return result.items[0];
}

pub const ProtobufParseResult = struct {
    parse_tree: proto.ParseResult,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ProtobufParseResult) void {
        self.parse_tree.deinit(self.allocator);
    }
};

pub fn parseProtobuf(allocator: std.mem.Allocator, sql: []const u8) Error!ProtobufParseResult {
    if (sql.len == 0) return error.EmptyInput;

    var result = c.pg_query_parse_protobuf(@ptrCast(sql.ptr));
    defer c.pg_query_free_protobuf_parse_result(result);

    try checkError(&result);

    const pbuf = result.parse_tree;
    const bytes: []const u8 = @ptrCast(pbuf.data[0..pbuf.len]);

    var reader: std.Io.Reader = .fixed(bytes);
    const parsed = try proto.ParseResult.decode(&reader, allocator);

    return ProtobufParseResult{
        .parse_tree = parsed,
        .allocator = allocator,
    };
}
