const std = @import("std");

const pg_query = @import("pg_query");

const support = @import("support.zig");

test "query.summary" {
    const outcome = try pg_query.query.summary(std.testing.allocator, "SELECT * FROM contacts", -1);
    var result = try support.unwrapOk(pg_query.SummaryResult, outcome);
    defer result.deinit();

    const tables = try result.tables(std.testing.allocator);
    defer std.testing.allocator.free(tables);

    try std.testing.expectEqual(@as(usize, 1), tables.len);
    try std.testing.expectEqualStrings("contacts", tables[0]);
}
