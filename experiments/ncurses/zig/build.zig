const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = [_][]const u8{
        "example2", "example7", "maze",
    };

    for (examples) |name| {
        // Building and running ex1
        const exe = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt("{s}.zig", .{name})),
                .target = target,
                .optimize = optimize,
            }),
        });

        exe.linkLibC();
        exe.addIncludePath(b.path("../ncurses-build/include"));
        exe.addObjectFile(b.path("../ncurses-build/lib/libncursesw.a"));

        b.installArtifact(exe);

        const run = b.addRunArtifact(exe);
        const step = b.step(
            b.fmt("run-{s}", .{name}),
            b.fmt("Run {s}", .{name}),
        );
        step.dependOn(&run.step);
    }
}
