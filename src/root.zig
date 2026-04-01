const std = @import("std");
pub const Allocator = std.mem.Allocator;

pub const pb = @import("pg_query_pb");
pub const NodeKind = pb.Node._node_case;

pub const api = @import("api/root.zig");
pub const ast = api.ast;
pub const query = api.query;
pub const raw = api.raw;
pub const errors = @import("error.zig");
pub const generated_mut = @import("generated_mut.zig");
pub const generated_node_mut = @import("generated_node_mut.zig");
pub const generated_node_ref = @import("generated_node_ref.zig");
pub const generated_result = @import("generated_result.zig");
pub const GeneratedParsedResult = generated_result.GeneratedParsedResult;
pub const generated_walk_exhaustive = @import("generated_walk_exhaustive.zig");
pub const node_ref = @import("node_ref.zig");
pub const NodeRef = node_ref.NodeRef;
pub const Context = node_ref.Context;
pub const ops = @import("ops.zig");
pub const parse_result = @import("parse_result.zig");
pub const query_result = @import("query_result.zig");
pub const SemanticParseResult = query_result.SemanticParseResult;
pub const QueryParseResult = SemanticParseResult;
pub const router = @import("router.zig");
pub const scan_result = @import("scan_result.zig");
pub const ScannedResult = scan_result.ScanResult;
pub const summary_result = @import("summary_result.zig");
pub const SummaryResult = summary_result.SummaryResult;
pub const truncate = @import("truncate.zig");

pub const c = @cImport({
    @cUndef("_FORTIFY_SOURCE");
    @cDefine("_FORTIFY_SOURCE", "0");
    @cDefine("__USE_FORTIFY_LEVEL", "0");
    @cDefine("__thread", "_Thread_local");
    @cInclude("pg_query.h");
    @cInclude("pg_query_raw.h");
    @cInclude("protobuf/pg_query.pb-c.h");
});

pub const ApiError = Allocator.Error || error{ContainsNulByte};
pub const ParseMode = enum(c_int) {
    default = c.PG_QUERY_PARSE_DEFAULT,
    type_name = c.PG_QUERY_PARSE_TYPE_NAME,
    plpgsql_expr = c.PG_QUERY_PARSE_PLPGSQL_EXPR,
    plpgsql_assign1 = c.PG_QUERY_PARSE_PLPGSQL_ASSIGN1,
    plpgsql_assign2 = c.PG_QUERY_PARSE_PLPGSQL_ASSIGN2,
    plpgsql_assign3 = c.PG_QUERY_PARSE_PLPGSQL_ASSIGN3,
};

pub const parse_mode_bits = c.PG_QUERY_PARSE_MODE_BITS;
pub const parse_mode_bitmask = c.PG_QUERY_PARSE_MODE_BITMASK;
pub const disable_backslash_quote = c.PG_QUERY_DISABLE_BACKSLASH_QUOTE;
pub const disable_standard_conforming_strings = c.PG_QUERY_DISABLE_STANDARD_CONFORMING_STRINGS;
pub const disable_escape_string_warning = c.PG_QUERY_DISABLE_ESCAPE_STRING_WARNING;

pub const pg_major_version = c.PG_MAJORVERSION;
pub const pg_version = c.PG_VERSION;
pub const pg_version_num: c_int = c.PG_VERSION_NUM;

pub const ErrorKind = enum {
    parse,
    scan,
    split,
    normalize,
    fingerprint,
    deparse,
    summary,
    plpgsql,
};

pub const LockMode = enum(i32) {
    NoLock = 0,
    AccessShareLock = 1,
    RowShareLock = 2,
    RowExclusiveLock = 3,
    ShareUpdateExclusiveLock = 4,
    ShareLock = 5,
    ShareRowExclusiveLock = 6,
    ExclusiveLock = 7,
    AccessExclusiveLock = 8,
};

pub const TriggerType = enum(i32) {
    Row = 1,
    Before = 2,
    Insert = 4,
    Delete = 8,
    Update = 16,
    Truncate = 32,
    Instead = 64,
};

pub const QueryError = struct {
    allocator: Allocator,
    kind: ErrorKind,
    message: []u8,
    funcname: ?[]u8,
    filename: ?[]u8,
    lineno: c_int,
    cursorpos: c_int,
    context: ?[]u8,

    pub fn deinit(self: *QueryError) void {
        self.allocator.free(self.message);
        if (self.funcname) |value| self.allocator.free(value);
        if (self.filename) |value| self.allocator.free(value);
        if (self.context) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

pub fn Outcome(comptime T: type) type {
    return union(enum) {
        ok: T,
        err: QueryError,

        pub fn deinit(self: *@This()) void {
            switch (self.*) {
                .ok => |*value| value.deinit(),
                .err => |*value| value.deinit(),
            }
        }
    };
}

pub const OwnedString = struct {
    allocator: Allocator,
    value: []u8,

    pub fn deinit(self: *OwnedString) void {
        self.allocator.free(self.value);
        self.* = undefined;
    }
};

pub const Fingerprint = struct {
    allocator: Allocator,
    value: u64,
    hex: []u8,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *Fingerprint) void {
        self.allocator.free(self.hex);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

pub const ParseResult = struct {
    allocator: Allocator,
    parse_tree: []u8,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *ParseResult) void {
        self.allocator.free(self.parse_tree);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

pub const ParsedResult = struct {
    allocator: Allocator,
    protobuf: *c.PgQuery__ParseResult,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *ParsedResult) void {
        c.pg_query__parse_result__free_unpacked(self.protobuf, null);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }

    pub fn deparse(self: *const ParsedResult, allocator: Allocator) ApiError!Outcome(OwnedString) {
        return ops.deparsePackedParseResult(allocator, self.protobuf);
    }

    pub fn stmtCount(self: *const ParsedResult) usize {
        return self.protobuf.n_stmts;
    }

    pub fn stmtNode(self: *const ParsedResult, index: usize) ?NodeRef {
        if (index >= self.protobuf.n_stmts) return null;
        const stmt = self.protobuf.stmts[index];
        if (stmt == null) return null;
        const node = stmt[0].stmt;
        if (node == null) return null;
        return node_ref.toRef(node);
    }
};

pub const ProtobufParseResult = struct {
    allocator: Allocator,
    parse_tree: []u8,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *ProtobufParseResult) void {
        self.allocator.free(self.parse_tree);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

pub const PlpgsqlParseResult = struct {
    allocator: Allocator,
    functions_json: []u8,

    pub fn deinit(self: *PlpgsqlParseResult) void {
        self.allocator.free(self.functions_json);
        self.* = undefined;
    }
};

pub const SummaryParseResult = struct {
    allocator: Allocator,
    summary: []u8,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *SummaryParseResult) void {
        self.allocator.free(self.summary);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

pub const ScanResult = struct {
    allocator: Allocator,
    protobuf: []u8,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *ScanResult) void {
        self.allocator.free(self.protobuf);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

pub const SplitStmt = struct {
    stmt_location: c_int,
    stmt_len: c_int,

    pub fn slice(self: SplitStmt, sql: []const u8) []const u8 {
        const start: usize = @intCast(self.stmt_location);
        const len: usize = @intCast(self.stmt_len);
        return sql[start .. start + len];
    }
};

pub const SplitResult = struct {
    allocator: Allocator,
    stmts: []SplitStmt,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *SplitResult) void {
        self.allocator.free(self.stmts);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

pub const RawScanToken = struct {
    start: c_int,
    end: c_int,
    token: c_int,
    keyword_kind: c_int,
};

pub const RawScanResult = struct {
    allocator: Allocator,
    tokens: []RawScanToken,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *RawScanResult) void {
        self.allocator.free(self.tokens);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

pub const RawParseResult = struct {
    allocator: Allocator,
    sql: []u8,
    parser_options: c_int,

    pub fn deinit(self: *RawParseResult) void {
        self.allocator.free(self.sql);
        self.* = undefined;
    }

    pub fn deparse(self: *const RawParseResult, allocator: Allocator) ApiError!Outcome(OwnedString) {
        return raw.deparse(allocator, self);
    }

    pub fn fingerprint(self: *const RawParseResult, allocator: Allocator) ApiError!Outcome(Fingerprint) {
        return raw.fingerprint(allocator, self);
    }
};

pub fn nodeToRef(node: *const pb.Node) ?generated_node_ref.NodeRef {
    return generated_node_ref.toRef(node);
}

pub fn nodeToMut(node: *pb.Node) ?generated_node_mut.NodeMut {
    return generated_node_mut.toMut(node);
}

pub fn nodeKind(node: *const pb.Node) ?NodeKind {
    const tagged = node.node orelse return null;
    return std.meta.activeTag(tagged);
}

test {
    std.testing.refAllDecls(@This());
}
