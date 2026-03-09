const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library module
    const mod = b.addModule("lc3_vm", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // Executable
    const exe = b.addExecutable(.{
        .name = "lc3_vm",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "lc3_vm", .module = mod },
            },
        }),
    });

    // Dependency
    const logly = b.dependency("logly", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("logly", logly.module("logly"));

    b.installArtifact(exe);

    // Run step: `zig build run -- [args]`
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Test step: `zig build test`
    // const mod_tests = b.addTest(.{ .root_module = mod });
    // const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    // const test_step = b.step("test", "Run tests");
    // test_step.dependOn(&b.addRunArtifact(mod_tests).step);
    // test_step.dependOn(&b.addRunArtifact(exe_tests).step);
}
