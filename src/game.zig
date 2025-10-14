//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Expose the sample board
pub const board_sample = @import("board.zig").sample;

// Import submodules
const Board = @import("board.zig").Board;
const State = @import("state.zig").State;
const Pos = @import("pos.zig").Pos;

pub const Dir = enum {
    Up,
    Down,
    Left,
    Right,
};

// - For the board we are only looking for wall (#) and floor (all other characters).
// - The position of the robot (@) and futur robots, boxes, traps... will be
//   part of the state of the game.
// - Board is static part, State is the moving part
// - Game is the Board + State
pub const Game = struct {
    board: Board,
    state: State,

    pub fn create(allocator: std.mem.Allocator, str: []const u8) !Game {
        const board = try Board.create(allocator, str);
        const state = try State.create(allocator, str);
        return .{
            .board = board,
            .state = state,
        };
    }

    pub fn destroy(self: *Game, allocator: std.mem.Allocator) void {
        self.board.destroy(allocator);
        self.state.destroy();
    }

    pub fn print(self: *const Game) void {
        var board_iter = self.board.iter();

        while (board_iter.next()) |cell| {
            if (cell.pos.col == 0) {
                std.debug.print("\n", .{});
            }

            // If we have an item at the given position print it, otherwise
            // print the tile.
            if (self.state.getItemAt(cell.pos)) |item| {
                std.debug.print("{c} ", .{item.toChar()});
            } else {
                std.debug.print("{c} ", .{cell.tile.toChar()});
            }
        }
        std.debug.print("\n\n", .{});
    }

    pub fn moveRobot(self: *Game, direction: Dir) !bool {
        const robot_pos = self.state.robotPos();

        const next_pos =
            switch (direction) {
                Dir.Up => if (robot_pos.row > 0) Pos{
                    .row = robot_pos.row - 1,
                    .col = robot_pos.col,
                } else null,
                Dir.Down => Pos{
                    .row = robot_pos.row + 1,
                    .col = robot_pos.col,
                },
                Dir.Left => if (robot_pos.col > 0) Pos{
                    .row = robot_pos.row,
                    .col = robot_pos.col - 1,
                } else null,
                Dir.Right => Pos{
                    .row = robot_pos.row,
                    .col = robot_pos.col + 1,
                },
            };

        if (next_pos == null) return false;
        const new_pos = next_pos.?;

        // Before moving we need to check if we will hit a wall
        if (self.board.cellIsFloor(new_pos)) {
            // And if there is already an item there
            if (self.state.getItemAt(new_pos)) |_| {
                std.debug.print("TODO: You hit something!!! what is this ???\n", .{});
            } else {
                try self.state.moveRobotTo(new_pos);
            }
        } else {
            std.debug.print("Oops, you hit a wall...\n", .{});
        }
        return false;
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
