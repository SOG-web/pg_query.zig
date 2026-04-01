const std = @import("std");

const pg_query = @import("pg_query");

pub fn unwrapOk(comptime T: type, outcome: pg_query.Outcome(T)) !T {
    return switch (outcome) {
        .ok => |value| value,
        .err => |err| {
            defer {
                var owned = err;
                owned.deinit();
            }
            std.debug.print("unexpected pg_query error: {s}\n", .{err.message});
            return error.UnexpectedPgQueryError;
        },
    };
}

pub fn expectErrorKind(comptime T: type, outcome: pg_query.Outcome(T), kind: pg_query.ErrorKind, message: []const u8) !void {
    switch (outcome) {
        .ok => |value| {
            var owned = value;
            owned.deinit();
            return error.ExpectedPgQueryError;
        },
        .err => |err| {
            defer {
                var owned = err;
                owned.deinit();
            }
            try std.testing.expectEqual(kind, err.kind);
            try std.testing.expectEqualStrings(message, err.message);
        },
    }
}
