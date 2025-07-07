const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{ .name = "vk", .root_module = exe_mod });

    const sdl_dep = b.dependency("sdl3", .{ .target = target, .optimize = optimize, .ext_image = true });
    exe.root_module.addImport("sdl3", sdl_dep.module("sdl3"));

    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.6",
        .profile = .core,
        .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });
    exe.root_module.addImport("gl", gl_bindings);

    const numz_dep = b.dependency("numz", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("numz", numz_dep.module("numz"));

    exe.linkSystemLibrary("vulkan");
    exe.linkSystemLibrary("SDL3_image");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
