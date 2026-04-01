const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

fn renderFilterColumns(
    allocator: std.mem.Allocator,
    columns: []const pg_query.summary_result.FilterColumn,
) ![][]u8 {
    const rendered = try allocator.alloc([]u8, columns.len);
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

fn freeRendered(allocator: std.mem.Allocator, rendered: [][]u8) void {
    for (rendered) |value| allocator.free(value);
    allocator.free(rendered);
}

fn lessThan(_: void, lhs: []u8, rhs: []u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}

test "query.parse exposes filter columns" {
    const outcome = try pg_query.query.parse(
        std.testing.allocator,
        "SELECT * FROM x WHERE x.y = $1 AND x.z = 1",
    );
    var parsed = try support.unwrapOk(pg_query.query.ParseResult, outcome);
    defer parsed.deinit();

    const rendered = try renderFilterColumns(std.testing.allocator, parsed.filterColumns());
    defer freeRendered(std.testing.allocator, rendered);
    std.sort.block([]u8, rendered, {}, lessThan);

    try std.testing.expectEqual(@as(usize, 2), rendered.len);
    try std.testing.expectEqualStrings("x.y", rendered[0]);
    try std.testing.expectEqualStrings("x.z", rendered[1]);
}

test "query.parse traverses filter columns through ctes" {
    const outcome = try pg_query.query.parse(
        std.testing.allocator,
        "WITH a AS (SELECT * FROM x WHERE x.y = $1 AND x.z = 1) SELECT * FROM a WHERE b = 5",
    );
    var parsed = try support.unwrapOk(pg_query.query.ParseResult, outcome);
    defer parsed.deinit();

    const rendered = try renderFilterColumns(std.testing.allocator, parsed.filterColumns());
    defer freeRendered(std.testing.allocator, rendered);
    std.sort.block([]u8, rendered, {}, lessThan);

    try std.testing.expectEqual(@as(usize, 3), rendered.len);
    try std.testing.expectEqualStrings("b", rendered[0]);
    try std.testing.expectEqualStrings("x.y", rendered[1]);
    try std.testing.expectEqualStrings("x.z", rendered[2]);
}
