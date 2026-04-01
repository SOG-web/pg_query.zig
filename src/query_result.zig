const std = @import("std");

const root = @import("root.zig");
const Allocator = root.Allocator;
const ApiError = root.ApiError;
const Context = root.Context;
const NodeRef = root.NodeRef;
const Outcome = root.Outcome;
const OwnedString = root.OwnedString;
const summary_mod = @import("summary_result.zig");

pub const SemanticParseResult = struct {
    allocator: Allocator,
    source_sql: []u8,
    parsed: root.GeneratedParsedResult,
    summary: summary_mod.SummaryResult,

    pub fn deinit(self: *ParseResult) void {
        self.allocator.free(self.source_sql);
        self.parsed.deinit();
        self.summary.deinit();
        self.* = undefined;
    }

    pub fn deparse(self: *const SemanticParseResult, allocator: Allocator) ApiError!Outcome(OwnedString) {
        return self.parsed.deparse(allocator);
    }

    pub fn deparseDirect(self: *const SemanticParseResult, allocator: Allocator) ApiError!Outcome(OwnedString) {
        const parsed = try root.ops.parseViaRawToGenerated(allocator, self.source_sql);
        switch (parsed) {
            .err => |err| return .{ .err = err },
            .ok => |value| {
                defer {
                    var owned = value;
                    owned.deinit();
                }
                return value.deparseDirect(allocator);
            },
        }
    }

    pub fn stmtCount(self: *const SemanticParseResult) usize {
        return self.parsed.stmtCount();
    }

    pub fn stmtNode(self: *const SemanticParseResult, index: usize) ?*const root.pb.Node {
        return self.parsed.stmtNode(index);
    }

    pub fn stmtNodeTyped(self: *const SemanticParseResult, index: usize) ?root.generated_node_ref.NodeRef {
        return self.parsed.stmtNodeTyped(index);
    }

    pub fn stmtNodeTypedMut(self: *SemanticParseResult, index: usize) ?root.generated_node_mut.NodeMut {
        return self.parsed.stmtNodeTypedMut(index);
    }

    pub fn tables(self: *const SemanticParseResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return self.summary.tables(allocator);
    }

    pub fn selectTables(self: *const SemanticParseResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return self.summary.selectTables(allocator);
    }

    pub fn dmlTables(self: *const SemanticParseResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return self.summary.dmlTables(allocator);
    }

    pub fn ddlTables(self: *const SemanticParseResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return self.summary.ddlTables(allocator);
    }

    pub fn functions(self: *const SemanticParseResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return self.summary.functions(allocator);
    }

    pub fn ddlFunctions(self: *const SemanticParseResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return self.summary.ddlFunctions(allocator);
    }

    pub fn callFunctions(self: *const SemanticParseResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return self.summary.callFunctions(allocator);
    }

    pub fn aliasesMap(self: *const SemanticParseResult) *const std.StringHashMap([]u8) {
        return self.summary.aliasesMap();
    }

    pub fn cteNames(self: *const SemanticParseResult) []const []u8 {
        return self.summary.cteNames();
    }

    pub fn filterColumns(self: *const SemanticParseResult) []const summary_mod.FilterColumn {
        return self.summary.filterColumns();
    }

    pub fn statementTypes(self: *const SemanticParseResult) []const []u8 {
        return self.summary.statementTypes();
    }

    pub fn warnings(self: *const SemanticParseResult) []const []const u8 {
        return self.summary.warnings;
    }

    pub fn truncate(self: *const SemanticParseResult, allocator: Allocator, max_length: usize) ApiError!Outcome(OwnedString) {
        const parsed = try root.ops.parseViaRawToGenerated(allocator, self.source_sql);
        switch (parsed) {
            .err => |err| return .{ .err = err },
            .ok => |value| {
                defer {
                    var owned = value;
                    owned.deinit();
                }
                return root.truncate.truncateGenerated(allocator, &value.protobuf, max_length);
            },
        }
    }
};

pub const ParseResult = SemanticParseResult;
