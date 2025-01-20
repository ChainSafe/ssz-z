const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "ssz",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const common_module = b.createModule(.{
        .root_source_file = b.path("../ssz/src/util/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const hash_module = b.createModule(.{
        .root_source_file = b.path("../ssz/src/hash/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.root_module.addImport("util", common_module);
    lib.root_module.addImport("hash", hash_module);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const hash_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/hash/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    hash_unit_tests.root_module.addImport("util", common_module);
    const run_hash_unit_tests = b.addRunArtifact(hash_unit_tests);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_tests.root_module.addImport("util", common_module);
    lib_unit_tests.root_module.addImport("hash", hash_module);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const ssz_module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    ssz_module.addImport("util", common_module);
    ssz_module.addImport("hash", hash_module);

    // Similar to the run step above, this creates a test step in test folder
    const run_lib_unit_valid_tests = addIntTest(b, target, optimize, common_module, hash_module, ssz_module);
    const run_lodestar_tests = addLodestarTest(b, target, optimize, common_module, hash_module, ssz_module);

    const unit_test_hash_step = b.step("test:unit:hash", "Run hash unit tests");
    unit_test_hash_step.dependOn(&run_hash_unit_tests.step);
    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    // TODO: cannot display information in "zig build test" https://github.com/ziglang/zig/issues/16673
    const unit_test_step = b.step("test:unit", "Run unit tests");
    unit_test_step.dependOn(&run_lib_unit_tests.step);

    const int_test_step = b.step("test:int", "Run integration/valid tests");
    int_test_step.dependOn(&run_lib_unit_valid_tests.step);

    const lodestar_test_step = b.step("test:lodestar", "Run Lodestar tests");
    lodestar_test_step.dependOn(&run_lodestar_tests.step);
}

fn addIntTest(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, common_module: *std.Build.Module, hash_module: *std.Build.Module, ssz_module: *std.Build.Module) *std.Build.Step.Run {
    return addTest("test/int/root.zig", b, target, optimize, common_module, hash_module, ssz_module);
}

fn addLodestarTest(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, common_module: *std.Build.Module, hash_module: *std.Build.Module, ssz_module: *std.Build.Module) *std.Build.Step.Run {
    return addTest("test/lodestar_types/root.zig", b, target, optimize, common_module, hash_module, ssz_module);
}

fn addTest(root_path: []const u8, b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, common_module: *std.Build.Module, hash_module: *std.Build.Module, ssz_module: *std.Build.Module) *std.Build.Step.Run {
    // Similar to the run step above, this creates a test step in test folder
    const lib_unit_valid_tests = b.addTest(.{
        .root_source_file = b.path(root_path),
        // use this to run a specific test
        // .root_source_file = b.path("test/int/type/vector_composite.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_valid_tests.root_module.addImport("util", common_module);
    lib_unit_valid_tests.root_module.addImport("hash", hash_module);
    lib_unit_valid_tests.root_module.addImport("ssz", ssz_module);

    const run_lib_unit_valid_tests = b.addRunArtifact(lib_unit_valid_tests);
    return run_lib_unit_valid_tests;
}
