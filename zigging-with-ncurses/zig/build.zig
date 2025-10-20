const std = @import("std");

pub fn build(b: *std.Build) !void {
    const hello_ncurses_exe = b.addExecutable(.{
        .name = "hello_ncurses",
        .root_module = b.createModule(.{
            .root_source_file = b.path("hello.zig"),
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
        }),
    });

    hello_ncurses_exe.linkLibC();
    hello_ncurses_exe.addObjectFile(.{ .cwd_relative = "/usr/lib/x86_64-linux-gnu/libncursesw.so.6.4" });

    b.installArtifact(hello_ncurses_exe);

    const run_step = b.step("run", "run the hello ncurses app");
    const run_cmd = b.addRunArtifact(hello_ncurses_exe);
    run_step.dependOn(&run_cmd.step);
}
