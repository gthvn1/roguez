//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Expose the sample board
pub const board_sample = @import("board.zig").sample;

// Import submodules
const Board = @import("board.zig").Board;
const State = @import("state.zig").State;

// - For the board we are only looking for wall (#) and floor (all other characters).
// - The position of the player (@) and futur robots, boxes, traps... will be
//   part of the state of the game.
// - Board is static part, State is the moving part
// - Game is the Board + State

pub const Game = struct {
    board: Board,
    state: State,

    pub fn create(allocator: std.mem.Allocator, str: []const u8) !Game {
        const board = try Board.create(allocator, str);
        const state = try State.init(str);
        return .{
            .board = board,
            .state = state,
        };
    }

    pub fn destroy(self: *Game, allocator: std.mem.Allocator) void {
        self.board.destroy(allocator);
        self.state.deinit();
    }

    pub fn print(self: *const Game) void {
        var board_iter = self.board.iter();
        const player_row = self.state.player_row;
        const player_col = self.state.player_col;

        while (board_iter.next()) |cell| {
            if (cell.col == 0) {
                std.debug.print("\n", .{});
            }

            if (cell.row == player_row and cell.col == player_col) {
                std.debug.print("P ", .{});
            } else {
                std.debug.print("{c} ", .{cell.tile.toChar()});
            }
        }
        std.debug.print("\n\n", .{});
        std.debug.print("player at row:{d} col:{d}\n", .{ self.state.player_row, self.state.player_col });
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
