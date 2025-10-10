const std = @import("std");
const roguez = @import("roguez");

pub fn main() !void {
    const GPAtype = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GPAtype{};
    const allocator = gpa.allocator();

    // Prints to stderr, ignoring potential errors.
    var g = try roguez.Game.create(allocator, roguez.board_str[0..]);
    defer g.destroy(allocator);

    while (true) {
        g.print();
        std.debug.print("==== HELP ====\n", .{});
        std.debug.print(" 'q' to quit\n", .{});
        std.debug.print(" 'h' to move left\n", .{});
        std.debug.print(" 'j' to move down\n", .{});
        std.debug.print(" 'k' to move up\n", .{});
        std.debug.print(" 'l' to move right\n", .{});
        std.debug.print("Press a key, then enter > ", .{});
        switch (roguez.readChar()) {
            'q' => break,
            else => continue,
        }
    }
}
