const std = @import("std");
const protobuf = @import("protobuf");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    translate_c.addIncludePath(b.path("libs"));

    const c_module = translate_c.createModule();

    const protobuf_dep = b.dependency("protobuf", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("pg_query", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "c", .module = c_module },
            .{ .name = "protobuf", .module = protobuf_dep.module("protobuf") },
        },
    });

    const proto_gen_mod = b.createModule(.{
        .root_source_file = b.path("src/proto_gen/pg_query.pb.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "protobuf", .module = protobuf_dep.module("protobuf") },
        },
    });
    mod.addImport("pg_query_proto", proto_gen_mod);

    const wf = b.addNamedWriteFiles("libs");
    _ = wf.addCopyFile(b.path("libs/libpg_query.a"), "libpg_query.a");
    _ = wf.addCopyFile(b.path("libs/pg_query.h"), "pg_query.h");

    const exe = b.addExecutable(.{
        .name = "pg_query",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "pg_query", .module = mod },
                .{ .name = "c", .module = c_module },
                .{ .name = "protobuf", .module = protobuf_dep.module("protobuf") },
            },
        }),
    });

    exe.root_module.addObjectFile(b.path("libs/libpg_query.a"));
    exe.root_module.addIncludePath(b.path("libs"));
    exe.use_llvm = true;

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const gen_proto = b.step("gen-proto", "generates zig files from protocol buffer definitions");
    const protoc_step = protobuf.RunProtocStep.create(protobuf_dep.builder, target, .{
        // out directory for the generated zig files
        .destination_directory = b.path("src/proto_gen"),
        // Optional LazyPath to `protoc`. If null, zig-protobuf will download Google's release of
        // the compiler.
        // .protoc = b.path("protoc"),
        .source_files = &.{
            b.path("proto/pg_query.proto"),
        },
        .include_directories = &.{b.path("proto")},
        // Preserve unknown fields during binary decode/encode round trips.
        // Defaults to false.
        .preserve_unknown_fields = false,
    });

    gen_proto.dependOn(&protoc_step.step);

    // The generated protobuf code contains recursive types (Node → node_union → * → Node)
    // where ~190 fields use `?Node` (value type), causing infinite size recursion.
    // This patch rewrites them to `?*Node` (pointer type) which breaks the cycle.
    // The zig-protobuf library already supports ?*MessageType at decode/encode/deinit.
    const patch_step = b.addSystemCommand(&.{ "sed", "-i", "s/: ?Node = null,/: ?*Node = null,/g", "src/proto_gen/pg_query.pb.zig" });
    patch_step.step.dependOn(&protoc_step.step);
    gen_proto.dependOn(&patch_step.step);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    mod_tests.root_module.addObjectFile(b.path("libs/libpg_query.a"));
    mod_tests.root_module.addIncludePath(b.path("libs"));
    mod_tests.use_llvm = true;

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    exe_tests.root_module.addObjectFile(b.path("libs/libpg_query.a"));
    exe_tests.root_module.addIncludePath(b.path("libs"));
    exe_tests.use_llvm = true;

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
