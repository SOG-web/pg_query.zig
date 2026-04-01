const std = @import("std");

const protobuf = @import("protobuf");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const protobuf_dep = b.dependency("protobuf", .{
        .target = target,
        .optimize = optimize,
    });
    const protobuf_mod = protobuf_dep.module("protobuf");

    const proto_step = protobuf.RunProtocStep.create(protobuf_dep.builder, target, .{
        .destination_directory = b.path("src/generated"),
        .source_files = &.{b.path("libpg_query/protobuf/pg_query.proto")},
        .include_directories = &.{b.path("libpg_query/protobuf")},
    });

    const pb_mod = b.createModule(.{
        .root_source_file = b.path("src/generated/pg_query.pb.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "protobuf", .module = protobuf_mod },
        },
    });

    const pg_query_mod = b.addModule("pg_query", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "protobuf", .module = protobuf_mod },
            .{ .name = "pg_query_pb", .module = pb_mod },
        },
    });
    addLibPgQuery(b, pg_query_mod, target, optimize) catch @panic("failed to configure libpg_query sources");

    const module_tests = b.addTest(.{
        .root_module = pg_query_mod,
    });
    module_tests.step.dependOn(&proto_step.step);

    const run_module_tests = b.addRunArtifact(module_tests);

    const external_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "pg_query", .module = pg_query_mod },
            },
        }),
    });
    external_tests.step.dependOn(&proto_step.step);

    const run_external_tests = b.addRunArtifact(external_tests);

    const test_step = b.step("test", "Run pg_query tests");
    test_step.dependOn(&run_module_tests.step);
    test_step.dependOn(&run_external_tests.step);

    const gen_proto = b.step("gen-proto", "Generate Zig bindings from pg_query.proto");
    gen_proto.dependOn(&proto_step.step);
}

fn addLibPgQuery(
    b: *std.Build,
    module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) !void {
    const root = "libpg_query";

    module.addIncludePath(b.path(root));
    module.addIncludePath(b.path(root ++ "/vendor"));
    module.addIncludePath(b.path(root ++ "/src/postgres/include"));
    module.addIncludePath(b.path(root ++ "/src/include"));

    if (target.result.os.tag == .windows) {
        module.addIncludePath(b.path(root ++ "/src/postgres/include/port/win32"));
        if (target.result.abi == .msvc) {
            module.addIncludePath(b.path(root ++ "/src/postgres/include/port/win32_msvc"));
        }
    }

    var files = std.array_list.Managed([]const u8).init(b.allocator);
    defer files.deinit();

    try collectTopLevelCFiles(b, &files, root, "src");
    try collectTopLevelCFiles(b, &files, root, "src/postgres");
    try files.append("vendor/protobuf-c/protobuf-c.c");
    try files.append("vendor/xxhash/xxhash.c");
    try files.append("protobuf/pg_query.pb-c.c");

    var flags = std.array_list.Managed([]const u8).init(b.allocator);
    defer flags.deinit();
    try flags.append("-std=gnu99");
    try flags.append("-Wno-everything");
    try flags.append("-U_FORTIFY_SOURCE");
    try flags.append("-D_FORTIFY_SOURCE=0");
    if (optimize == .Debug) {
        try flags.append("-DUSE_ASSERT_CHECKING");
    }

    module.addCSourceFiles(.{
        .root = b.path(root),
        .files = files.items,
        .flags = flags.items,
    });
}

fn collectTopLevelCFiles(
    b: *std.Build,
    files: *std.array_list.Managed([]const u8),
    root: []const u8,
    dir_path: []const u8,
) !void {
    const io = b.graph.io;
    const root_relative = try std.fs.path.join(b.allocator, &.{ root, dir_path });
    defer b.allocator.free(root_relative);
    const full_path = b.pathFromRoot(root_relative);
    defer b.allocator.free(full_path);

    var dir = try std.Io.Dir.cwd().openDir(io, full_path, .{ .iterate = true });
    defer dir.close(io);

    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (std.mem.endsWith(u8, entry.name, ".c")) {
            try files.append(try std.fs.path.join(b.allocator, &.{ dir_path, entry.name }));
        }
    }
}
