const std = @import("std");
const r = @import("roguez");

pub fn main() !void {
    const GPAtype = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GPAtype{};
    const allocator = gpa.allocator();
    const map = @import("map.zig").map;

    // We need to set the terminal in Raw mode to avoid pressing enter
    // TODO:
    //   - Should we restore the old_settings?
    //   - Can we avoid doing this each time readChar is called?
    var settings: std.os.linux.termios = undefined;
    _ = std.os.linux.tcgetattr(0, &settings);

    // Disabling canonical mode allow the input to be immediatly available
    settings.lflag.ICANON = false;

    _ = std.os.linux.tcsetattr(0, std.posix.TCSA.NOW, &settings);
    // we can now read character without pressing enter

    var g = try r.Game.create(allocator, map);
    defer g.destroy(allocator);

    while (true) {
        g.print();
        std.debug.print("==== HELP ====\n", .{});
        std.debug.print(" 'q' quit\n", .{});
        std.debug.print(" 'h' move left\n", .{});
        std.debug.print(" 'j' move down\n", .{});
        std.debug.print(" 'k' move up\n", .{});
        std.debug.print(" 'l' move right\n", .{});
        std.debug.print(" 'd' drop an item\n", .{});
        std.debug.print(" You can use arrows to move\n", .{});
        switch (r.readChar()) {
            'h', 0x44 => try g.moveRobot(r.Dir.left),
            'j', 0x42 => try g.moveRobot(r.Dir.down),
            'k', 0x41 => try g.moveRobot(r.Dir.up),
            'l', 0x43 => try g.moveRobot(r.Dir.right),
            'd' => try g.dropItem(),
            'q' => break,
            else => continue,
        }
    }
}
