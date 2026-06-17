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

## Usage

```zig
const pg_query = @import("pg_query");

pub fn main() !void {
    var result = pg_query.parse(allocator, "SELECT 1") catch |err| {
        std.log.err("parse error: {}", .{err});
        return;
    };
    defer result.deinit();

    std.debug.print("{s}\n", .{result.parse_tree});
}
```

## Project Structure

```
pg_query.zig/
├── libs/                          # Pre-built libpg_query files
│   ├── libpg_query.a              # Static library
│   ├── pg_query.h                 # Public C API header
│   └── postgres_deparse.h         # Deparse API header
├── src/
│   ├── c.h                        # Wrapper header for translate-c
│   ├── root.zig                   # Zig API (parse, normalize, etc.)
│   └── main.zig                   # Example executable
├── proto/                         # Protobuf definitions (optional)
├── scripts/
│   └── update-libpg_query.sh      # Upgrade script for libpg_query
├── build.zig
└── build.zig.zon
```

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
