//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Expose the sample board
pub const board_sample = @import("board.zig").sample;

// Import submodules
const Board = @import("board.zig").Board;
const State = @import("state.zig").State;
const Pos = @import("pos.zig").Pos;
const Item = @import("item.zig").Item;

pub const Dir = enum {
    up,
    down,
    left,
    right,
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
        var buf: [5]u8 = undefined;

        while (board_iter.next()) |cell| {
            if (cell.pos.col == 0) {
                std.debug.print("\n", .{});
            }

            // If we have an item at the given position print it, otherwise
            // print the tile.
            if (self.state.getItemAt(cell.pos)) |item| {
                std.debug.print("{s} ", .{item.toChar(&buf)});
            } else {
                std.debug.print("{s} ", .{cell.tile.toChar(&buf)});
            }
        }
        std.debug.print("\n\n", .{});
    }

    pub fn moveRobot(self: *Game, direction: Dir) !void {
        const robot_pos = self.state.robotPos();

        const next_pos =
            switch (direction) {
                Dir.up => if (robot_pos.row > 0) Pos{
                    .row = robot_pos.row - 1,
                    .col = robot_pos.col,
                } else null,
                Dir.down => Pos{
                    .row = robot_pos.row + 1,
                    .col = robot_pos.col,
                },
                Dir.left => if (robot_pos.col > 0) Pos{
                    .row = robot_pos.row,
                    .col = robot_pos.col - 1,
                } else null,
                Dir.right => Pos{
                    .row = robot_pos.row,
                    .col = robot_pos.col + 1,
                },
            };

        if (next_pos == null) return;
        const new_pos = next_pos.?;

        // Before moving we need to check if we will hit something
        switch (self.board.getTileAt(new_pos)) {
            .wall => std.debug.print("Oops, you hit a wall...\n", .{}),
            .flag => std.debug.print("TODO: You find the flag\n", .{}),
            .floor => {
                // is there already an item there?
                if (self.state.getItemAt(new_pos)) |item| {
                    if (self.handleItemAt(item, new_pos, direction)) {
                        try self.state.moveRobotTo(new_pos);
                    } else {
                        var buf: [5]u8 = undefined;
                        std.debug.print("Robot hit {s} that cannot be moved in that direction\n", .{item.toChar(
                            &buf,
                        )});
                    }
                } else {
                    try self.state.moveRobotTo(new_pos);
                }
            },
        }
    }

    // returns try if we can move a box from pos in the given direction
    fn canMoveBox(self: *const Game, pos: Pos, dir: Dir) bool {
        _ = self;
        _ = pos;
        const dir_str = switch (dir) {
            Dir.up => "TODO: try to push the box upward\n",
            Dir.down => "TODO: try to push the box downward\n",
            Dir.left => "TODO: try to push the box to the left\n",
            Dir.right => "TODO: try to push the box to the right\n\n",
        };
        std.debug.print("{s}", .{dir_str});
        return false;
    }

    // There is an [item] at position [pos] that prevents the robot to move.
    // If [item] can move we move it and return true, otherwise we return
    // false.
    fn handleItemAt(self: *Game, item: Item, pos: Pos, dir: Dir) bool {
        switch (item) {
            .robot => unreachable,
            .box => {
                if (self.canMoveBox(pos, dir)) {
                    std.debug.print("TODO: move the box\n", .{});
                    return true;
                }
            },
            .key => std.debug.print("TODO: You hit a key, you can't move there...\n", .{}),
            .door => std.debug.print("TODO: There is a closed door here\n", .{}),
        }

        return false;
    }
};

pub fn readChar() u8 {
    var stdin_buffer: [1]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    const carlu: u8 = stdin.peekByte() catch return 0;

    std.debug.print("\nYou pressed: 0x{x}\n", .{carlu});
    return carlu;
}
