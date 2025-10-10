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

pub const board_str =
    \\########
    \\#......#
    \\#......#
    \\#...@..#
    \\#......#
    \\#......#
    \\########
;

pub const Board = struct {
    b: [][]u8,

    pub fn create(allocator: std.mem.Allocator, str: []const u8) !Board {
        // We need to know the number of rows in [str] to be able to allocate [b] correctly.
        // So we do a first iteration to compute the number of rows.
        var str_it = std.mem.tokenizeSequence(u8, str, "\n");
        var row_count: usize = 0;
        while (str_it.next()) |_| {
            row_count += 1;
        }

        // Now we can allocate rows and go through each strings.
        var b = try allocator.alloc([]u8, row_count);
        var idx: usize = 0;
        str_it = std.mem.tokenizeSequence(u8, str, "\n");
        while (str_it.next()) |line| {
            b[idx] = try allocator.alloc(u8, line.len);
            std.mem.copyForwards(u8, b[idx], line);
            idx += 1;
        }

        return .{ .b = b };
    }

    pub fn destroy(self: *Board, allocator: std.mem.Allocator) void {
        for (self.b) |row| {
            allocator.free(row);
        }
        allocator.free(self.b);
    }

    pub fn print(self: *Board) void {
        std.debug.print("\n", .{});
        for (self.b) |row| {
            for (row) |cell| {
                std.debug.print("{c} ", .{cell});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
};

pub fn readChar() u8 {
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
    var stdin_buffer: [1]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    const carlu: u8 = stdin.peekByte() catch return 0;

    std.debug.print("\nYou pressed: 0x{x}\n", .{carlu});
    return carlu;
}
