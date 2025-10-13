pub const Pos = struct {
    row: usize,
    col: usize,

    pub fn isEqualTo(self: *const Pos, pos: Pos) bool {
        return self.row == pos.row and self.col == pos.col;
    }
};
