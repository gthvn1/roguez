const std = @import("std");
const roguez = @import("roguez");

pub fn main() void {
    // Prints to stderr, ignoring potential errors.
    while (true) {
        roguez.Board.print();
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

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
