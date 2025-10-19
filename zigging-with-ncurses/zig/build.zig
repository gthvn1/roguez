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

    // TODO: check if there is a better way to get the relative path for
    // ncurses. Remember that I built it and install it in $HOME/opt/ncurses.
    const home = std.posix.getenv("HOME") orelse {
        std.debug.print("Failed to get HOME\n", .{});
        return;
    };

    const ncurses_include_path = try std.fs.path.join(
        b.allocator,
        &[_][]const u8{ home, "opt/ncurses/include/" },
    );

    const ncurses_include_relpath = try std.fs.path.relative(
        b.allocator,
        ".",
        ncurses_include_path,
    );

    const ncurses_lib_path = try std.fs.path.join(
        b.allocator,
        &[_][]const u8{ home, "opt/ncurses/lib64/" },
    );

    const ncurses_lib_relpath = try std.fs.path.relative(
        b.allocator,
        ".",
        ncurses_lib_path,
    );

    hello_ncurses_exe.linkLibC();
    hello_ncurses_exe.addIncludePath(b.path(ncurses_include_relpath));
    hello_ncurses_exe.addLibraryPath(b.path(ncurses_lib_relpath));
    hello_ncurses_exe.linkSystemLibrary("ncurses");

    b.installArtifact(hello_ncurses_exe);

    const run_step = b.step("run", "run the hello ncurses app");
    const run_cmd = b.addRunArtifact(hello_ncurses_exe);
    run_step.dependOn(&run_cmd.step);
}
