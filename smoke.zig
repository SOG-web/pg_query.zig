const std = @import("std");

const pg_query = @import("pg_query");

const Mode = enum {
    parse,
    summary,
    analyze,
    all,

    fn fromText(text: []const u8) ?Mode {
        if (std.ascii.eqlIgnoreCase(text, "parse")) return .parse;
        if (std.ascii.eqlIgnoreCase(text, "summary")) return .summary;
        if (std.ascii.eqlIgnoreCase(text, "analyze")) return .analyze;
        if (std.ascii.eqlIgnoreCase(text, "all")) return .all;
        return null;
    }
};

fn unwrapOrPrintError(
    comptime T: type,
    allocator: std.mem.Allocator,
    outcome: pg_query.Outcome(T),
) !T {
    _ = allocator;
    switch (outcome) {
        .ok => |value| return value,
        .err => |err| {
            defer {
                var owned = err;
                owned.deinit();
            }
            std.debug.print("pg_query error: {s}\n", .{err.message});
            return error.PgQueryFailed;
        },
    }
}

fn printUsage(argv0: []const u8) void {
    std.debug.print(
        \\usage: {s} [parse|summary|analyze|all] [sql]
        \\example: {s} summary "select 1"
        \\example: {s} all "select pg_is_in_recovery() as in_recovery from pg_sleep(1)"
        \\
    , .{ argv0, argv0, argv0 });
}

fn runParse(allocator: std.mem.Allocator, sql: []const u8) !void {
    var parsed = try unwrapOrPrintError(
        pg_query.QueryParseResult,
        allocator,
        try pg_query.query.parse(allocator, sql),
    );
    defer parsed.deinit();
    std.debug.print("parse ok: statements={d}\n", .{parsed.stmtCount()});
    const statement_types = parsed.statementTypes();
    std.debug.print("parse statement_types={d}\n", .{statement_types.len});
    for (statement_types, 0..) |statement_type, index| {
        std.debug.print("parse statement_type[{d}]={s}\n", .{ index, statement_type });
    }
}

fn runSummary(allocator: std.mem.Allocator, sql: []const u8) !void {
    var summary = try unwrapOrPrintError(
        pg_query.SummaryResult,
        allocator,
        try pg_query.query.summary(allocator, sql, -1),
    );
    defer summary.deinit();
    const statement_types = summary.statementTypes();
    std.debug.print("summary ok: statement_types={d}\n", .{statement_types.len});
    for (statement_types, 0..) |statement_type, index| {
        std.debug.print("summary statement_type[{d}]={s}\n", .{ index, statement_type });
    }
}

fn runAnalyze(allocator: std.mem.Allocator, sql: []const u8) !void {
    var analysis = try unwrapOrPrintError(
        pg_query.router.BatchAnalysis,
        allocator,
        try pg_query.router.analyzeSql(allocator, sql),
    );
    defer analysis.deinit();
    std.debug.print(
        "analyze ok: decision={s} category={s} reason={s} statements={d} safe_on_replica={}\n",
        .{
            @tagName(analysis.decision),
            @tagName(analysis.category),
            @tagName(analysis.requires_primary_reason),
            analysis.statement_count,
            analysis.safeOnReplica(),
        },
    );
    for (analysis.statement_categories, 0..) |category, index| {
        std.debug.print("analyze statement_category[{d}]={s}\n", .{ index, @tagName(category) });
    }
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const argv = try init.minimal.args.toSlice(allocator);
    defer allocator.free(argv);

    const argv0 = if (argv.len > 0) argv[0] else "pg_query_smoke";
    if (argv.len > 3) {
        printUsage(argv0);
        return error.InvalidArguments;
    }

    const mode = if (argv.len >= 2) Mode.fromText(argv[1]) orelse {
        printUsage(argv0);
        return error.InvalidArguments;
    } else .all;
    const sql = if (argv.len >= 3) argv[2] else "select 1";

    std.debug.print("smoke mode: {s}\n", .{@tagName(mode)});
    std.debug.print("smoke sql: {s}\n", .{sql});

    switch (mode) {
        .parse => try runParse(allocator, sql),
        .summary => try runSummary(allocator, sql),
        .analyze => try runAnalyze(allocator, sql),
        .all => {
            try runParse(allocator, sql);
            try runSummary(allocator, sql);
            try runAnalyze(allocator, sql);
        },
    }
}
