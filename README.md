# pg_query.zig

Zig package for PostgreSQL query parsing, normalization, fingerprinting, deparsing, scanning, and summary extraction on top of `libpg_query`.

## Features

- Parse SQL into a Zig-native semantic result with summary metadata
- Parse via raw `libpg_query` structures when needed
- Normalize and fingerprint queries
- Deparse parsed trees back to SQL
- Scan and split SQL text
- Parse PL/pgSQL

## Install

### Local path dependency

```zig
.dependencies = .{
    .pg_query = .{
        .path = "deps/pg_query.zig",
    },
},
```

### Git dependency

After publishing the package, use the repo URL:

```zig
.dependencies = .{
    .pg_query = .{
        .url = "git+https://github.com/SOG-web/pg_query.zig#main",
        .hash = "pg_query-REPLACE_WITH_ZIG_FETCH_HASH",
    },
},
```

Then in `build.zig`:

```zig
const pg_query_dep = b.dependency("pg_query", .{
    .target = target,
    .optimize = optimize,
});
const pg_query_mod = pg_query_dep.module("pg_query");
```

And import it in your module:

```zig
const exe_mod = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
    .imports = &.{
        .{ .name = "pg_query", .module = pg_query_mod },
    },
});
```

## Complete Usage Cycle

This example shows a typical end-to-end flow:

1. parse the SQL
2. inspect statement types and referenced tables
3. normalize the SQL
4. fingerprint it
5. truncate it for logging
6. deparse it back to SQL

```zig
const std = @import("std");
const pg_query = @import("pg_query");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sql =
        \\SELECT u.id, u.email
        \\FROM users u
        \\WHERE u.email = 'alice@example.com'
        \\ORDER BY u.id DESC
    ;

    var parsed = switch (try pg_query.query.parse(allocator, sql)) {
        .ok => |value| value,
        .err => |err| {
            defer {
                var owned = err;
                owned.deinit();
            }
            std.debug.print("parse error: {s}\n", .{err.message});
            return;
        },
    };
    defer parsed.deinit();

    const stmt_types = parsed.statementTypes();
    for (stmt_types) |stmt_type| {
        std.debug.print("statement type: {s}\n", .{stmt_type});
    }

    const tables = try parsed.tables(allocator);
    defer allocator.free(tables);
    for (tables) |table| {
        std.debug.print("table: {s}\n", .{table});
    }

    var normalized = switch (try pg_query.query.normalize(allocator, sql)) {
        .ok => |value| value,
        .err => |err| {
            defer {
                var owned = err;
                owned.deinit();
            }
            std.debug.print("normalize error: {s}\n", .{err.message});
            return;
        },
    };
    defer normalized.deinit();
    std.debug.print("normalized: {s}\n", .{normalized.value});

    var fingerprint = switch (try pg_query.query.fingerprint(allocator, sql)) {
        .ok => |value| value,
        .err => |err| {
            defer {
                var owned = err;
                owned.deinit();
            }
            std.debug.print("fingerprint error: {s}\n", .{err.message});
            return;
        },
    };
    defer fingerprint.deinit();
    std.debug.print("fingerprint: {s}\n", .{fingerprint.hex});

    var truncated = switch (try parsed.truncate(allocator, 48)) {
        .ok => |value| value,
        .err => |err| {
            defer {
                var owned = err;
                owned.deinit();
            }
            std.debug.print("truncate error: {s}\n", .{err.message});
            return;
        },
    };
    defer truncated.deinit();
    std.debug.print("truncated: {s}\n", .{truncated.value});

    var deparsed = switch (try parsed.deparse(allocator)) {
        .ok => |value| value,
        .err => |err| {
            defer {
                var owned = err;
                owned.deinit();
            }
            std.debug.print("deparse error: {s}\n", .{err.message});
            return;
        },
    };
    defer deparsed.deinit();
    std.debug.print("deparsed: {s}\n", .{deparsed.value});
}
```

## Development

Generate protobuf bindings:

```sh
zig build gen-proto
```

Run tests:

```sh
zig build test --summary all
```
