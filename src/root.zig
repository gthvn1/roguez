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

// Import submodules
pub const State = @import("state.zig").State;
pub const Board = @import("board.zig").Board;

pub const board_str =
    \\########
    \\#......#
    \\#......#
    \\#...@..#
    \\#......#
    \\#......#
    \\########
;

// - For the board we are only looking for wall (#) and floor (all other characters).
// - The position of the player (@) and futur robots, boxes, traps... will be
//   part of the state of the game.
// - Board is static part, State is the moving part

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
