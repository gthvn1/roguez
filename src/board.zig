const std = @import("std");
const Pos = @import("pos.zig").Pos;
const Glyph = @import("glyph.zig").Glyph;

pub const Tile = enum {
    wall,
    floor,
    flag,

    pub fn fromChar(c: u8) Tile {
        return switch (c) {
            '#' => .wall,
            '$' => .flag,
            else => .floor,
        };
    }

    pub fn toGlyph(self: Tile) Glyph {
        // https://www.unicodecharacter.org/
        const wall = "\u{2612}";
        const flag = "\u{2691}";

        return switch (self) {
            .wall => Glyph.fromUtf8(wall),
            .flag => Glyph.fromUtf8(flag),
            .floor => Glyph.fromChar(' '),
        };
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

    pub fn iter(self: *const Board) Iterator {
        return .{
            .board = self,
            .pos = .{ .row = 0, .col = 0 },
        };
    }

    const Iterator = struct {
        board: *const Board,
        pos: Pos,

        const BoardCell = struct {
            tile: Tile,
            pos: Pos,
        };

        pub fn next(it: *Iterator) ?BoardCell {
            if (it.pos.row >= it.board.b.len) return null;

            const raw_col = it.board.b[it.pos.row];

            if (it.pos.col >= raw_col.len) return null;

            const cell = BoardCell{
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
};
