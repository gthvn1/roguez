const std = @import("std");

pub const State = struct {
    player_col: usize,
    player_row: usize,

    pub fn init(str: []const u8) State {
        // TODO: really find the row and col in the map or return an error
        _ = str;
        return .{
            .player_col = 0,
            .player_row = 0,
        };
    }

    pub fn deinit(self: *const State) void {
        // Nothing to deinit for now. Keep it for symetrie
        _ = self;
    }
};
