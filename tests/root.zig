const std = @import("std");

test {
    _ = @import("deparse_test.zig");
    _ = @import("filter_column_test.zig");
    _ = @import("fingerprint_test.zig");
    _ = @import("normalize_test.zig");
    _ = @import("parallel_test.zig");
    _ = @import("parse_plpgsql_test.zig");
    _ = @import("query_test.zig");
    _ = @import("raw_acceptance_test.zig");
    _ = @import("raw_test.zig");
    _ = @import("summary_parity_test.zig");
    _ = @import("summary_test.zig");
    _ = @import("summary_truncate_parity_test.zig");
    _ = @import("truncate_test.zig");
}
