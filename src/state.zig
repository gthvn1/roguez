const std = @import("std");

const player_tile: u8 = '@';

const StateError = error{
    PlayerNotFound,
};

pub const State = struct {
    player_col: usize,
    player_row: usize,

    pub fn init(str: []const u8) !State {
        // TODO: really find the row and col in the map or null if not found.
        var row: usize = 0;
        var col: usize = 0;

        for (str) |c| {
            if (c == player_tile) {
                return .{
                    .player_row = row,
                    .player_col = col,
                };
            }

            if (c == '\n') {
                row += 1;
                col = 0;
            } else {
                col += 1;
            }
        }

        return StateError.PlayerNotFound;
    }

    pub fn deinit(self: *const State) void {
        // Nothing to deinit for now. Keep it for symetrie
        _ = self;
    }
};
