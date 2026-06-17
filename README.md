# pg_query.zig

Zig bindings for [libpg_query](https://github.com/pganalyze/libpg_query) — the PostgreSQL parser library. Uses the actual PostgreSQL server source to parse SQL queries and return the internal PostgreSQL parse tree.

Currently wraps **libpg_query 18.4** (PostgreSQL 18).

## Requirements

- [Zig](https://ziglang.org/) 0.16.0+

## Building

```sh
zig build
```

The build uses Zig's `translate-c` to auto-generate C bindings from the libpg_query headers, then links against the pre-built `libpg_query.a` static library.

## Exports from `root.zig`

| Export | Type | Description |
|---|---|---|
| `proto` | module | Generated protobuf types (`pg_query.ParseResult`, `pg_query.ScanResult`, `pg_query.Node`, etc.) |
| `libpg_query` | module | Raw C bindings via `translate-c` (`c.pg_query_parse`, `c.pg_query_scan`, `c.PgQueryParseResult`, etc.) |

The `libpg_query` export gives direct access to all C functions and types from `pg_query.h` if you need lower-level control.

## Usage

### JSON parsing (string output)

```zig
const pg_query = @import("pg_query");

pub fn main() !void {
    var result = try pg_query.parse(allocator, "SELECT 1");
    defer result.deinit();

    // result.parse_tree is a JSON string
    std.debug.print("{s}\n", .{result.parse_tree});
}
```

### Protobuf parsing (typed output)

```zig
const pg_query = @import("pg_query");

pub fn main() !void {
    var result = try pg_query.parseProtobuf(allocator, "SELECT * FROM users WHERE id = 1");
    defer result.deinit();

    // result.parse_tree is a decoded pg_query.ParseResult protobuf struct
    const stmts = result.parse_tree.stmts.items;
    for (stmts) |stmt| {
        if (stmt.stmt) |node| {
            if (node.node) |n| {
                // n is a node_union with variants like .select_stmt, .insert_stmt, etc.
                std.debug.print("statement type: {}\n", .{n});
            }
        }
    }
}
```

### Available functions

| Function | Returns | Description |
|---|---|---|
| `parse(alloc, sql)` | `ParseResult` | Parse SQL to JSON string |
| `parseProtobuf(alloc, sql)` | `ProtobufParseResult` | Parse SQL to typed protobuf AST structs |
| `scanProtobuf(alloc, sql)` | `ProtobufScanResult` | Tokenize SQL to typed protobuf token structs |
| `normalize(alloc, sql)` | `NormalizeResult` | Normalize SQL (replace literals with `$1`, `$2`, ...) |
| `normalizeUtility(alloc, sql)` | `NormalizeResult` | Normalize including utility statements |
| `fingerprint(alloc, sql)` | `FingerPrintResult` | Compute query fingerprint hash |
| `splitWithScanner(alloc, sql)` | `SplitResult` | Split multi-statement SQL (scanner) |
| `splitWithParser(alloc, sql)` | `SplitResult` | Split multi-statement SQL (parser) |
| `parsePlpgsql(alloc, sql)` | `ParseResult` | Parse PL/pgSQL functions |
| `isUtilityStmt(sql)` | `bool` | Check if SQL is a utility statement |

> **Protobuf vs JSON:** `parse` returns a raw JSON string. `parseProtobuf` and `scanProtobuf` return decoded Zig structs with typed fields (e.g., `stmt.stmt.?.node.?.select_stmt`). Use protobuf when you need to traverse the AST programmatically.

## Project Structure

```
pg_query.zig/
├── libs/                          # Pre-built libpg_query files
│   ├── libpg_query.a              # Static library
│   ├── pg_query.h                 # Public C API header
│   └── postgres_deparse.h         # Deparse API header
├── src/
│   ├── c.h                        # Wrapper header for translate-c
│   ├── root.zig                   # Public API facade
│   ├── pg_query.zig               # Core implementation
│   ├── main.zig                   # Example executable
│   └── proto_gen/                 # Generated protobuf code
│       └── pg_query.pb.zig        # Auto-generated (patched for recursive types)
├── proto/
│   └── pg_query.proto             # Protobuf schema for PostgreSQL AST nodes
├── scripts/
│   └── update-libpg_query.sh      # Upgrade script for libpg_query
├── build.zig
└── build.zig.zon
```

## Build Steps

| Step | Command | Description |
|---|---|---|
| Build | `zig build` | Compile the library and executable |
| Test | `zig build test` | Run all tests |
| Run | `zig build run` | Run the example executable |
| Generate proto | `zig build gen-proto` | Generate Zig protobuf bindings from `proto/pg_query.proto` |

### Protobuf code generation

`zig build gen-proto` does two things:
1. Runs `protoc` to generate `src/proto_gen/pg_query.pb.zig` from `proto/pg_query.proto`
2. Patches the generated file to fix recursive type dependencies (`?Node` → `?*Node`)

The PostgreSQL AST has recursive types (e.g., `Node` contains `node_union` which contains structs that reference `Node` back). Zig requires all types to have a known size at compile time, so the generated `?Node` value types cause infinite recursion. The patch rewrites these to `?*Node` (pointers), which have a fixed known size. The [zig-protobuf](https://github.com/SOG-web/zig-protobuf) library already supports pointer submessage types in its decode/encode/deinit paths.

## Upgrading libpg_query

The `libs/` directory contains pre-built files from [libpg_query](https://github.com/pganalyze/libpg_query). To upgrade:

### Automated (recommended)

```sh
./scripts/update-libpg_query.sh        # defaults to 18-latest branch
./scripts/update-libpg_query.sh 17-latest   # or specify a branch
```

This clones libpg_query, runs `make`, and copies the 3 required files into `libs/`.

### Manual

```sh
git clone -b 18-latest --depth 1 git://github.com/pganalyze/libpg_query /tmp/libpg_query
cd /tmp/libpg_query
make
cp libpg_query.a pg_query.h postgres_deparse.h /path/to/pg_query.zig/libs/
rm -rf /tmp/libpg_query
```

Only 3 files are needed in `libs/`:
- `libpg_query.a` — the pre-built static library
- `pg_query.h` — public API header
- `postgres_deparse.h` — deparse types (included by `pg_query.h`)

## Known Issues

On Arch Linux (and other distros with GCC 15+/glibc 2.43+), the system `crt1.o` contains `.sframe` sections that Zig's self-hosted linker does not yet support. The build uses `use_llvm = true` as a workaround to link with LLVM's lld instead.

## License

MIT — see [LICENSE](LICENSE).

The bundled libpg_query library is licensed under the [PostgreSQL License](https://www.postgresql.org/about/licence/) and the 3-clause BSD license. See [libs/](libs/) or the [upstream repo](https://github.com/pganalyze/libpg_query) for details.
