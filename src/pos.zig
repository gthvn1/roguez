pub const Dir = enum {
    up,
    down,
    left,
    right,
};

pub const Pos = struct {
    row: usize,
    col: usize,

    pub fn isEqualTo(self: *const Pos, pos: Pos) bool {
        return self.row == pos.row and self.col == pos.col;
    }

    pub fn next(self: *const Pos, dir: Dir) ?Pos {
        return switch (dir) {
            Dir.up => if (self.row > 0) Pos{
                .row = self.row - 1,
                .col = self.col,
            } else null,
            Dir.down => Pos{
                .row = self.row + 1,
                .col = self.col,
            },
            Dir.left => if (self.col > 0) Pos{
                .row = self.row,
                .col = self.col - 1,
            } else null,
            Dir.right => Pos{
                .row = self.row,
                .col = self.col + 1,
            },
        };
    }
};
