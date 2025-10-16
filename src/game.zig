//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Expose the sample board
pub const board_sample = @import("board.zig").sample;

// Import submodules
const Board = @import("board.zig").Board;
const State = @import("state.zig").State;
const Pos = @import("pos.zig").Pos;
pub const Dir = @import("pos.zig").Dir;
const Item = @import("item.zig").Item;

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
                std.debug.print("{s} ", .{item.toUtf8(&buf)});
            } else {
                std.debug.print("{s} ", .{cell.tile.toUtf8(&buf)});
            }
        }
        std.debug.print("\n\n", .{});
    }

    pub fn moveRobot(self: *Game, direction: Dir) !void {
        const next_pos = self.state.robotPos().next(direction) orelse return;

        // Before moving we need to check if we will hit something
        switch (self.board.getTileAt(next_pos)) {
            .wall => std.debug.print("Oops, you hit a wall...\n", .{}),
            .flag => std.debug.print("TODO: You find the flag\n", .{}),
            .floor => {
                // is there already an item there?
                if (self.state.getItemAt(next_pos)) |item| {
                    if (self.handleItemAt(item, next_pos, direction)) {
                        try self.state.moveRobotTo(next_pos);
                    } else {
                        var buf: [5]u8 = undefined;
                        std.debug.print("Hit {s} that cannot be moved in that direction\n", .{item.toUtf8(
                            &buf,
                        )});
                    }
                } else {
                    try self.state.moveRobotTo(next_pos);
                }
            },
        }
    }

    /// There is an [item] at position [pos] that prevents the robot to move.
    /// [handleItemAt] takes care of moving it. If the item cannot be moved
    /// it returns false, otherwise true.
    fn handleItemAt(self: *Game, item: Item, pos: Pos, dir: Dir) bool {
        switch (item) {
            .robot => unreachable,
            .box => return self.handleBox(pos, dir),
            .key => std.debug.print("TODO: You hit a key, you can't move there...\n", .{}),
            .door => std.debug.print("TODO: There is a closed door here\n", .{}),
        }

        return false;
    }

    /// if we can move a box from pos in the given direction do it and
    /// returns true. Otherwise returns false.
    fn handleBox(self: *Game, pos: Pos, dir: Dir) bool {
        const next_pos = pos.next(dir) orelse return false;
        switch (self.board.getTileAt(next_pos)) {
            .floor => {
                if (self.state.getItemAt(next_pos)) |_| {
                    std.debug.print("TODO: An item blocks the path\n", .{});
                    return false;
                }
                self.state.moveBox(pos, next_pos) catch return false;
                return true;
            },
            .wall => {
                std.debug.print("A wall is in the path\n", .{});
            },
            .flag => {
                std.debug.print("TODO: You catch the flag no?...\n", .{});
            },
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
