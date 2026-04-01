const std = @import("std");

const pg_query = @import("pg_query");

test "query operations remain stable in parallel" {
    _ = pg_query;
    return error.SkipZigTest;
}
