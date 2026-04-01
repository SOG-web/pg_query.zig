const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}

fn renderFilterColumns(
    allocator: std.mem.Allocator,
    columns: []const pg_query.summary_result.FilterColumn,
) ![][]const u8 {
    const rendered = try allocator.alloc([]const u8, columns.len);
    errdefer allocator.free(rendered);

    for (rendered, columns) |*dest, column| {
        if (column.table_name) |table_name| {
            dest.* = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ table_name, column.column });
        } else {
            dest.* = try allocator.dupe(u8, column.column);
        }
    }
    return rendered;
}

fn freeRendered(allocator: std.mem.Allocator, rendered: [][]const u8) void {
    for (rendered) |value| allocator.free(value);
    allocator.free(rendered);
}

fn expectSummaryColumns(sql: []const u8, expected: []const []const u8) !void {
    const outcome = try pg_query.query.summary(std.testing.allocator, sql, -1);
    var result = try support.unwrapOk(pg_query.SummaryResult, outcome);
    defer result.deinit();

    const rendered = try renderFilterColumns(std.testing.allocator, result.filterColumns());
    defer freeRendered(std.testing.allocator, rendered);
    std.sort.block([]const u8, rendered, {}, lessThan);

    try std.testing.expectEqual(expected.len, rendered.len);
    for (expected, rendered) |want, got| {
        try std.testing.expectEqualStrings(want, got);
    }
}

test "summary filter columns cover boolean and null tests" {
    try expectSummaryColumns(
        "SELECT * FROM x WHERE x.y IS TRUE AND x.z IS NOT FALSE",
        &.{ "x.y", "x.z" },
    );
    try expectSummaryColumns(
        "SELECT * FROM x WHERE x.y IS NULL AND x.z IS NOT NULL",
        &.{ "x.y", "x.z" },
    );
}

test "summary filter columns cover coalesce and set operations" {
    try expectSummaryColumns(
        "SELECT * FROM x WHERE x.y = COALESCE(z.a, z.b)",
        &.{ "x.y", "z.a", "z.b" },
    );
    try expectSummaryColumns(
        "SELECT * FROM x where y = $1 UNION SELECT * FROM x where z = $2",
        &.{ "y", "z" },
    );
    try expectSummaryColumns(
        "SELECT * FROM x where y = $1 UNION ALL SELECT * FROM x where z = $2",
        &.{ "y", "z" },
    );
    try expectSummaryColumns(
        "SELECT * FROM x where y = $1 EXCEPT SELECT * FROM x where z = $2",
        &.{ "y", "z" },
    );
    try expectSummaryColumns(
        "SELECT * FROM x where y = $1 INTERSECT ALL SELECT * FROM x where z = $2",
        &.{ "y", "z" },
    );
}

test "summary filter columns ignore target list and order by columns" {
    try expectSummaryColumns(
        "SELECT a, y, z FROM x WHERE x.y = $1 AND x.z = 1",
        &.{ "x.y", "x.z" },
    );
    try expectSummaryColumns(
        "SELECT * FROM x WHERE x.y = $1 AND x.z = 1 ORDER BY a, b",
        &.{ "x.y", "x.z" },
    );
}
