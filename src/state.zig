const std = @import("std");

const StateError = error{
    RobotNotFound,
};

pub const State = struct {
    robot_row: usize,
    robot_col: usize,

    const robot_tile: u8 = '@';

    pub fn init(str: []const u8) !State {
        // TODO: really find the row and col in the map or null if not found.
        var row: usize = 0;
        var col: usize = 0;

        for (str) |c| {
            if (c == robot_tile) {
                std.debug.print("Found robot at row {d} col {d}\n", .{ row, col });
                return .{
                    .robot_row = row,
                    .robot_col = col,
                };
            }

            if (c == '\n') {
                row += 1;
                col = 0;
            } else {
                col += 1;
            }
        }

        return StateError.RobotNotFound;
    }

    pub fn isRobotAt(self: *const State, row: usize, col: usize) bool {
        return row == self.robot_row and
            col == self.robot_col;
    }

    pub fn deinit(self: *const State) void {
        // Nothing to deinit for now. Keep it for symetrie
        _ = self;
    }
};
