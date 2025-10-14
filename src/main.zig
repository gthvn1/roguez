const std = @import("std");
const r = @import("roguez");

pub fn main() !void {
    const GPAtype = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GPAtype{};
    const allocator = gpa.allocator();
    const map = @import("map.zig").map;

    // Prints to stderr, ignoring potential errors.
    var g = try r.Game.create(allocator, map);
    defer g.destroy(allocator);

    while (true) {
        g.print();
        std.debug.print("==== HELP ====\n", .{});
        std.debug.print(" 'q' to quit\n", .{});
        std.debug.print(" 'h' to move left\n", .{});
        std.debug.print(" 'j' to move down\n", .{});
        std.debug.print(" 'k' to move up\n", .{});
        std.debug.print(" 'l' to move right\n", .{});
        std.debug.print(" You can use arrows to move\n", .{});
        switch (r.readChar()) {
            'h', 0x44 => _ = try g.moveRobot(r.Dir.Left),
            'j', 0x42 => _ = try g.moveRobot(r.Dir.Down),
            'k', 0x41 => _ = try g.moveRobot(r.Dir.Up),
            'l', 0x43 => _ = try g.moveRobot(r.Dir.Right),
            'q' => break,
            else => continue,
        }
    }
}
