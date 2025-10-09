//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Our board is ROW x COL
// For example we can have:
//
//     ########
//     #......#
//     #......#
//     ########
//
// - It is a 4 x 8 board
// - Top left is 0 x 0
// - Bottom right is 3 x 7
// - We consider the X-axis from left to right (that is COL)
// - We consider the Y-axis from top to bottom (that is ROW)
// - So (ROW, COL) <=> (Y, X)

const row_sz: comptime_int = 4;
const col_sz: comptime_int = 8;
const board: [row_sz][col_sz]u8 = [row_sz][col_sz]u8{
    [_]u8{'.'} ** col_sz,
    [_]u8{'.'} ** col_sz,
    [_]u8{'.'} ** col_sz,
    [_]u8{'.'} ** col_sz,
};

pub fn printBoard() void {
    for (board) |row| {
        for (row) |cell| {
            std.debug.print("{c} ", .{cell});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

pub fn bufferedPrint() !void {
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try stdout.flush(); // Don't forget to flush!
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
