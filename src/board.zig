const std = @import("std");
const Pos = @import("pos.zig").Pos;

const Tile = union(enum) {
    wall,
    floor,
    door: u8,

    pub fn fromChar(c: u8) Tile {
        return switch (c) {
            '#' => .wall,
            'A'...'Z' => .{ .door = c },
            else => .floor,
        };
    }

    pub fn toChar(self: Tile, buf: *[4]u8) *[4]u8 {
        // https://symbl.cc/en/unicode-table
        const wall = "\u{25A0}";

        switch (self) {
            .wall => std.mem.copyForwards(u8, buf, wall),
            .floor => std.mem.copyForwards(u8, buf, &[_]u8{ 0x20, 0, 0, 0 }),
            .door => |d| std.mem.copyForwards(u8, buf, &[_]u8{ d, 0, 0, 0 }),
        }

        return buf;
    }
};

const Cell = struct {
    tile: Tile,
    pos: Pos,
};

const BoardIterator = struct {
    board: *const Board,
    pos: Pos,

    pub fn next(it: *BoardIterator) ?Cell {
        if (it.pos.row >= it.board.b.len) return null;

        const raw_col = it.board.b[it.pos.row];

        if (it.pos.col >= raw_col.len) return null;

        const cell = Cell{
            .pos = it.pos,
            .tile = raw_col[it.pos.col],
        };

        // advance iterator
        it.pos.col += 1;
        // and check if we reached the end of a row
        if (it.pos.col == raw_col.len) {
            it.pos.row += 1;
            it.pos.col = 0;
        }

        return cell;
    }
};

pub const Board = struct {
    b: [][]Tile,

    pub fn create(allocator: std.mem.Allocator, str: []const u8) !Board {
        // We need to know the number of rows in [str] to be able to allocate [b] correctly.
        // So we do a first iteration to compute the number of rows.
        var str_it = std.mem.tokenizeSequence(u8, str, "\n");
        var row_count: usize = 0;
        while (str_it.next()) |_| {
            row_count += 1;
        }

        // Now we can allocate rows and go through each strings.
        var b = try allocator.alloc([]Tile, row_count);
        var row_idx: usize = 0;
        str_it = std.mem.tokenizeSequence(u8, str, "\n");

        while (str_it.next()) |line| {
            b[row_idx] = try allocator.alloc(Tile, line.len);
            for (line, 0..) |c, col_idx| {
                b[row_idx][col_idx] = Tile.fromChar(c);
            }
            row_idx += 1;
        }

        return .{ .b = b };
    }

    pub fn destroy(self: *Board, allocator: std.mem.Allocator) void {
        for (self.b) |row| {
            allocator.free(row);
        }
        allocator.free(self.b);
    }

    pub fn getTileAt(self: *Board, pos: Pos) Tile {
        return self.b[pos.row][pos.col];
    }

    pub fn iter(self: *const Board) BoardIterator {
        return .{
            .board = self,
            .pos = .{ .row = 0, .col = 0 },
        };
    }
};
