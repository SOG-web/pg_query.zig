const std = @import("std");

const root = @import("root.zig");
const walk = @import("generated_walk_exhaustive.zig");

pub const GeneratedParsedResult = struct {
    allocator: root.Allocator,
    protobuf: root.pb.ParseResult,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *ParsedResult) void {
        self.protobuf.deinit(self.allocator);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }

    pub fn deparse(self: *const GeneratedParsedResult, allocator: root.Allocator) root.ApiError!root.Outcome(root.OwnedString) {
        return root.ops.deparseGeneratedParseResult(allocator, &self.protobuf);
    }

    pub fn deparseDirect(self: *const GeneratedParsedResult, allocator: root.Allocator) root.ApiError!root.Outcome(root.OwnedString) {
        return root.ops.deparseGeneratedParseResult(allocator, &self.protobuf);
    }

    pub fn stmtCount(self: *const GeneratedParsedResult) usize {
        return self.protobuf.stmts.items.len;
    }

    pub fn stmtNode(self: *const GeneratedParsedResult, index: usize) ?*const root.pb.Node {
        if (index >= self.protobuf.stmts.items.len) return null;
        const stmt = &self.protobuf.stmts.items[index];
        if (stmt.stmt) |node| return node;
        return null;
    }

    pub fn stmtNodeTyped(self: *const GeneratedParsedResult, index: usize) ?root.generated_node_ref.NodeRef {
        return root.parse_result.stmtNodeTyped(&self.protobuf, index);
    }

    pub fn stmtNodeTypedMut(self: *GeneratedParsedResult, index: usize) ?root.generated_node_mut.NodeMut {
        return root.parse_result.stmtNodeTypedMut(&self.protobuf, index);
    }

    pub fn nodes(self: *const GeneratedParsedResult, allocator: std.mem.Allocator) std.mem.Allocator.Error![]walk.VisitedNode {
        return walk.collectNodes(allocator, &self.protobuf);
    }

    pub fn nodesMut(self: *GeneratedParsedResult, allocator: std.mem.Allocator) std.mem.Allocator.Error![]walk.VisitedNodeMut {
        return root.generated_walk_exhaustive.collectNodesMut(allocator, &self.protobuf);
    }

    pub fn truncate(self: *const GeneratedParsedResult, allocator: root.Allocator, max_length: usize) root.ApiError!root.Outcome(root.OwnedString) {
        return root.truncate.truncateGenerated(allocator, &self.protobuf, max_length);
    }

    pub fn statementTypes(self: *const GeneratedParsedResult, allocator: std.mem.Allocator) std.mem.Allocator.Error![][]const u8 {
        return root.parse_result.statementTypes(allocator, &self.protobuf);
    }
};

pub const ParsedResult = GeneratedParsedResult;

pub const ScanResult = struct {
    allocator: root.Allocator,
    protobuf: root.pb.ScanResult,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *ScanResult) void {
        self.protobuf.deinit(self.allocator);
        if (self.stderr_buffer) |value| self.allocator.free(value);
        self.* = undefined;
    }

    pub fn tokenCount(self: *const ScanResult) usize {
        return self.protobuf.tokens.items.len;
    }
};

pub fn fromRawScan(
    allocator: root.Allocator,
    version: i32,
    tokens: []const root.RawScanToken,
    stderr_buffer: ?[]const u8,
) root.ApiError!ScanResult {
    var protobuf: root.pb.ScanResult = .{
        .version = version,
        .tokens = .empty,
    };
    errdefer protobuf.deinit(allocator);

    try protobuf.tokens.ensureTotalCapacity(allocator, tokens.len);
    for (tokens) |token| {
        protobuf.tokens.appendAssumeCapacity(.{
            .start = token.start,
            .end = token.end,
            .token = @enumFromInt(token.token),
            .keyword_kind = @enumFromInt(token.keyword_kind),
        });
    }

    return .{
        .allocator = allocator,
        .protobuf = protobuf,
        .stderr_buffer = if (stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
    };
}
