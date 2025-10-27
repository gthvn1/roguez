const std = @import("std");
const r = @import("roguez");
const Ansi = r.Ansi;

pub fn main() !void {
    const GPAtype = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GPAtype{};
    const allocator = gpa.allocator();
    const map = @import("map.zig").map;

    // We need to set the terminal in Raw mode to avoid pressing enter
    var settings: std.os.linux.termios = undefined;
    _ = std.os.linux.tcgetattr(0, &settings);

    const old_settings = settings;

    // Disabling canonical mode allow the input to be immediatly available
    settings.lflag.ICANON = false;

    _ = std.os.linux.tcsetattr(0, std.posix.TCSA.NOW, &settings);
    // we can now read character without pressing enter

    // Prepare the output
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var g = try r.Game.create(allocator, stdout, map);
    defer g.destroy(allocator);

    while (true) {
        try g.print();
        switch (r.readChar()) {
            'h', 0x44 => try g.moveRobot(r.Dir.left),
            'j', 0x42 => try g.moveRobot(r.Dir.down),
            'k', 0x41 => try g.moveRobot(r.Dir.up),
            'l', 0x43 => try g.moveRobot(r.Dir.right),
            'q' => break,
            else => continue,
        }
    }

    // Restore old settings
    _ = std.os.linux.tcsetattr(0, std.posix.TCSA.NOW, &old_settings);
}
