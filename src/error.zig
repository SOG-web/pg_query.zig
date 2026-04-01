const std = @import("std");

const root = @import("root.zig");
pub const Result = root.Outcome;

pub const Kind = enum {
    conversion,
    decode,
    parse,
    invalid_json,
    invalid_pointer,
    scan,
    split,
    normalize,
    fingerprint,
    deparse,
    summary,
    plpgsql,
};

pub fn describe(kind: Kind) []const u8 {
    return switch (kind) {
        .conversion => "Invalid statement format",
        .decode => "Error decoding result",
        .parse => "Invalid statement",
        .invalid_json => "Error parsing JSON",
        .invalid_pointer => "Invalid pointer",
        .scan => "Error scanning",
        .split => "Error splitting",
        .normalize => "Error normalizing",
        .fingerprint => "Error fingerprinting",
        .deparse => "Error deparsing",
        .summary => "Error summarizing",
        .plpgsql => "Error parsing PL/pgSQL",
    };
}

pub fn format(
    allocator: std.mem.Allocator,
    kind: Kind,
    detail: []const u8,
) (std.mem.Allocator.Error || error{ContainsNulByte})!root.QueryError {
    return .{
        .allocator = allocator,
        .kind = switch (kind) {
            .scan => .scan,
            .split => .split,
            .normalize => .normalize,
            .fingerprint => .fingerprint,
            .deparse => .deparse,
            .summary => .summary,
            .plpgsql => .plpgsql,
            else => .parse,
        },
        .message = try std.fmt.allocPrint(allocator, "{s}: {s}", .{ describe(kind), detail }),
        .funcname = null,
        .filename = null,
        .lineno = 0,
        .cursorpos = 0,
        .context = null,
    };
}
