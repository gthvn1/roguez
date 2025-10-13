pub const Pos = struct {
    row: usize,
    col: usize,

    pub fn init(row: usize, col: usize) Pos {
        return .{
            .row = row,
            .col = col,
        };
    }
};
