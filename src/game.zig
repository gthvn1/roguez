//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Expose the sample board
pub const board_sample = @import("board.zig").sample;

// Import submodules
const Board = @import("board.zig").Board;
const Tile = @import("board.zig").Tile;

const State = @import("state.zig").State;
const Item = @import("state.zig").Item;

const Pos = @import("pos.zig").Pos;
pub const Dir = @import("pos.zig").Dir;

pub const Ansi = @import("ansi.zig").Ansi;

// - For the board we are only looking for wall (#) and floor (all other characters).
// - The position of the robot (@) and futur robots, boxes, traps... will be
//   part of the state of the game.
// - Board is static part, State is the moving part
// - Game is the Board + State
pub const Game = struct {
    board: Board,
    state: State,

    const GameCell = struct {
        tile: Tile, // Tile is from board
        item: ?Item,
    };

    fn getCellAt(self: *Game, pos: Pos) GameCell {
        return .{
            .tile = self.board.getTileAt(pos),
            .item = self.state.getItemAt(pos),
        };
    }

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

    pub fn print(self: *const Game, term: *const Ansi, start_line: usize) !void {
        var current_line = start_line;

        try term.setColor(Ansi.Color.white);
        try term.setBold();
        try term.setItalic();
        try term.setUnderline();
        try term.writeStrNoFlush("Robot items", current_line, 1);

        // Reset stuff for items
        try term.resetAll();
        try term.setColor(Ansi.Color.white);
        try term.writeCharNoFlush(':');
        try term.writeCharNoFlush(' ');

        var it = self.state.robot.items_iterator();
        while (it.next()) |i| {
            switch (i) {
                .key => |k| try term.writeCharNoFlush(k),
                .empty => try term.writeCharNoFlush('.'),
                else => unreachable,
            }
            try term.writeCharNoFlush(' ');
        }
        // Reset all does the flush
        try term.resetAll();

        // New we print the board
        current_line += 2; // Add an extra line for clarity
        try term.setColor(Ansi.Color.white);
        try term.setBold();
        try term.setItalic();
        try term.setUnderline();
        try term.writeStrAndFlush("Board", current_line, 1);
        try term.resetAll();

        current_line += 1;
        try term.moveCursorTo(current_line, 1);
        try term.eraseLine(current_line);

        // TODO: From here use term to display the board with colors
        var board_iter = self.board.iter();
        while (board_iter.next()) |cell| {
            if (cell.pos.col == 0) {
                current_line += 1;
                try term.moveCursorTo(current_line, 1);
                try term.eraseLine(current_line);
            }

            // If we have an item at the given position print it, otherwise
            // print the tile.
            if (self.state.getItemAt(cell.pos)) |item| {
                switch (item) {
                    .key => |k| {
                        try term.setColor(Ansi.Color.magenta);
                        try term.writeCharNoFlush(k);
                    },
                    .door => |d| {
                        try term.setColor(Ansi.Color.cyan);
                        try term.writeCharNoFlush(d);
                    },
                    .box => {
                        try term.setColor(Ansi.Color.yellow);
                        try term.writeCharNoFlush('&');
                    },
                    .robot => {
                        try term.setColor(Ansi.Color.blue);
                        try term.writeCharNoFlush('@');
                    },
                    .empty => {
                        try term.resetColor();
                        try term.writeCharNoFlush(' ');
                    },
                }
            } else {
                switch (cell.tile) {
                    .wall => {
                        try term.setReverse();
                        try term.setColor(Ansi.Color.white);
                        try term.writeCharNoFlush(' ');
                    },
                    .flag => {
                        try term.setColor(Ansi.Color.red);
                        try term.writeCharNoFlush('$');
                    },
                    .floor => {
                        try term.resetColor();
                        try term.writeCharNoFlush(' ');
                    },
                }
            }

            try term.resetAll();
        }

        current_line += 2;
        try term.moveCursorTo(current_line, 1);
        try term.resetAll();
    }

    pub fn moveRobot(self: *Game, direction: Dir) !void {
        const next_pos = self.state.robotPos().next(direction) orelse return;
        const next_cell = self.getCellAt(next_pos);

        // Before moving we need to check if we will hit something
        switch (next_cell.tile) {
            .wall => std.debug.print("Oops, you hit a wall...\n", .{}),
            .flag => std.debug.print("🏁 Victory! The robot has captured the flag!\n", .{}),

            .floor => {
                if (next_cell.item) |item| {
                    if (self.handleItemAt(item, next_pos, direction)) {
                        try self.state.moveRobotTo(next_pos);
                    }
                    // If we failed to handle item (typically we cannot move it) then
                    // we do nothing. The reason it failed should be reported by the
                    // item handler.
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
        return switch (item) {
            .robot => unreachable,
            .box => self.handleBox(pos, dir),
            .key => |k| self.handleKey(pos, k),
            .door => |d| self.handleDoor(d),
            .empty => return true,
        };
    }

    /// if we can move a box from pos in the given direction do it and
    /// returns true. Otherwise returns false.
    fn handleBox(self: *Game, pos: Pos, dir: Dir) bool {
        const next_pos = pos.next(dir) orelse return false;
        const next_cell = self.getCellAt(next_pos);

        switch (next_cell.tile) {
            .floor => {
                if (next_cell.item) |_| {
                    std.debug.print("TODO: An item blocks the path\n", .{});
                    return false;
                }
                self.state.moveBox(pos, next_pos) catch return false;
                return true;
            },
            .wall => std.debug.print("A wall blocks our path!\n", .{}),
            .flag => std.debug.print("TODO: You catch the flag no?...\n", .{}),
        }

        return false;
    }

    fn handleKey(self: *Game, pos: Pos, key: u8) bool {
        if (self.state.robot.addKey(key)) {
            try self.state.removeKey(pos);
            return true;
        } else {
            std.debug.print("It looks like you can not take a new key\n", .{});
            return false;
        }
    }

    fn handleDoor(self: *Game, door: u8) bool {
        const key = std.ascii.toLower(door);
        const has_key = self.state.robot.hasKey(key);
        if (!has_key) {
            std.debug.print("You need key <{c}> to open the door...", .{key});
        }

        return has_key;
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
