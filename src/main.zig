const std = @import("std");

const pg_query = @import("pg_query");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    _ = init.minimal;

    const sql = "SELECT id, name FROM users WHERE id = 42";

    // JSON parse (returns raw JSON string)
    const parsed = pg_query.parse(arena, sql) catch |err| {
        std.log.err("parse error: {}", .{err});
        return;
    };
    std.debug.print("=== JSON parse ===\n{s}\n\n", .{parsed.parse_tree});

    // Protobuf parse (returns typed Zig structs)
    var pb_result = pg_query.parseProtobuf(arena, sql) catch |err| {
        std.log.err("protobuf parse error: {}", .{err});
        return;
    };
    defer pb_result.deinit();

    std.debug.print("=== Protobuf parse ===\n", .{});
    const stmts = pb_result.parse_tree.stmts.items;
    std.debug.print("statements: {}\n", .{stmts.len});
    for (stmts, 0..) |stmt, i| {
        std.debug.print("  [{d}] stmt_location: {}, stmt_len: {}\n", .{ i, stmt.stmt_location, stmt.stmt_len });
        if (stmt.stmt) |node| {
            if (node.node) |n| {
                switch (n) {
                    .select_stmt => |sel| {
                        std.debug.print("    SelectStmt: target_list={} items, from_clause={} items\n", .{ sel.target_list.items.len, sel.from_clause.items.len });
                    },
                    else => {
                        std.debug.print("    (other statement type)\n", .{});
                    },
                }
            }
        }
    }

    // Protobuf scan (returns typed token structs)
    std.debug.print("\n=== Protobuf scan ===\n", .{});
    var scan_result = pg_query.scanProtobuf(arena, sql) catch |err| {
        std.log.err("scan error: {}", .{err});
        return;
    };
    defer scan_result.deinit();

    const tokens = scan_result.scan_tree.tokens.items;
    std.debug.print("tokens: {}\n", .{tokens.len});
    for (tokens) |tok| {
        std.debug.print("  [{d}..{d}] token={} keyword={}\n", .{ tok.start, tok.end, @intFromEnum(tok.token), @intFromEnum(tok.keyword_kind) });
    }

    // Normalize (returns SQL with literals replaced by $1, $2, ...)
    const norm = pg_query.normalize(arena, "SELECT * FROM users WHERE age > 30 AND name = 'foo'") catch |err| {
        std.log.err("normalize error: {}", .{err});
        return;
    };
    std.debug.print("\n=== Normalize ===\n{s}\n", .{norm.normalized});
}
