const std = @import("std");

const ops = @import("../ops.zig");
const root = @import("../root.zig");
pub const ParseResult = root.QueryParseResult;
pub const GeneratedParseResult = root.GeneratedParsedResult;
pub const SummaryResult = root.SummaryResult;
pub const SplitResult = root.SplitResult;
pub const ScannedResult = root.ScannedResult;
pub const Fingerprint = root.Fingerprint;
pub const OwnedString = root.OwnedString;
pub const PlpgsqlParseResult = root.PlpgsqlParseResult;
pub const Outcome = root.Outcome;

pub fn parse(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(ParseResult) {
    return ops.parseDetailed(allocator, sql);
}

pub fn parseGenerated(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(GeneratedParseResult) {
    return ops.parseGenerated(allocator, sql);
}

pub fn parseViaRawDetailed(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(ParseResult) {
    return ops.parseViaRawDetailed(allocator, sql);
}

pub fn parseViaRawToGenerated(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(GeneratedParseResult) {
    return ops.parseViaRawToGenerated(allocator, sql);
}

pub fn deparse(allocator: root.Allocator, parsed_tree: *const root.pb.ParseResult) root.ApiError!Outcome(OwnedString) {
    return ops.deparseGeneratedParseResult(allocator, parsed_tree);
}

pub fn deparseNode(allocator: root.Allocator, node: *const root.pb.Node) root.ApiError!Outcome(OwnedString) {
    const ref = root.nodeToRef(node) orelse return .{ .err = .{
        .allocator = allocator,
        .kind = .deparse,
        .message = try std.fmt.allocPrint(allocator, "cannot deparse empty node", .{}),
        .funcname = null,
        .filename = null,
        .lineno = 0,
        .cursorpos = 0,
        .context = null,
    } };
    return ref.deparse(allocator);
}

pub fn deparseNodeDirect(allocator: root.Allocator, node: *const root.pb.Node) root.ApiError!Outcome(OwnedString) {
    const ref = root.nodeToRef(node) orelse return .{ .err = .{
        .allocator = allocator,
        .kind = .deparse,
        .message = try std.fmt.allocPrint(allocator, "cannot directly deparse empty node", .{}),
        .funcname = null,
        .filename = null,
        .lineno = 0,
        .cursorpos = 0,
        .context = null,
    } };
    return ref.deparseDirect(allocator);
}

pub fn normalize(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(OwnedString) {
    return ops.normalize(allocator, sql);
}

pub fn fingerprint(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(Fingerprint) {
    return ops.fingerprint(allocator, sql);
}

pub fn parsePlpgsql(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(root.PlpgsqlParseResult) {
    return ops.parsePlpgsql(allocator, sql);
}

pub fn scan(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(ScannedResult) {
    return ops.scanDetailed(allocator, sql);
}

pub fn splitWithParser(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(SplitResult) {
    return ops.splitWithParser(allocator, sql);
}

pub fn splitWithScanner(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(SplitResult) {
    return ops.splitWithScanner(allocator, sql);
}

pub fn summary(allocator: root.Allocator, sql: []const u8, truncate_limit: i32) root.ApiError!Outcome(SummaryResult) {
    return ops.summaryDetailed(allocator, sql, 0, truncate_limit);
}
