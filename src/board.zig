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

pub const sample =
    \\############
    \\#....o.....#
    \\#......o...#
    \\#...@......#
    \\#.....#....#
    \\#.....#....#
    \\############
;

const Cell = struct {
    row: usize,
    col: usize,
    car: u8,
};

const BoardIterator = struct {
    board: *const Board,
    row: usize,
    col: usize,

    pub fn next(it: *BoardIterator) ?Cell {
        if (it.row >= it.board.b.len) return null;
        const board_col = it.board.b[it.row];

        if (it.col >= board_col.len) return null;

        const cell = Cell{
            .row = it.row,
            .col = it.col,
            .car = board_col[it.col],
        };

        // Update the iterator
        if (it.col + 1 == board_col.len) {
            it.row = it.row + 1;
            it.col = 0;
        } else {
            it.col += 1;
        }

        return cell;
    }
};

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
        var row_idx: usize = 0;
        str_it = std.mem.tokenizeSequence(u8, str, "\n");

        while (str_it.next()) |line| {
            b[row_idx] = try allocator.alloc(u8, line.len);
            for (line, 0..) |c, col_idx| {
                if (c == '#') {
                    b[row_idx][col_idx] = '#';
                } else {
                    b[row_idx][col_idx] = '.';
                }
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

    pub fn iter(self: *const Board) BoardIterator {
        return .{
            .board = self,
            .row = 0,
            .col = 0,
        };
    }
};
