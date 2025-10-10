const std = @import("std");

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
        var idx: usize = 0;
        str_it = std.mem.tokenizeSequence(u8, str, "\n");

        // TODO: only read wall and floor. Other items are not port of the board
        // and should be ignored.
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

    pub fn iter(self: *const Board) BoardIterator {
        return .{
            .board = self,
            .row = 0,
            .col = 0,
        };
    }
};
