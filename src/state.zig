const std = @import("std");
const Pos = @import("pos.zig").Pos;

const StateError = error{
    RobotNotFound,
};

pub const State = struct {
    robot_pos: Pos,

    const robot_tile: u8 = '@';

    pub fn init(str: []const u8) !State {
        // TODO: really find the row and col in the map or null if not found.
        var cpos = Pos{ .row = 0, .col = 0 };

        for (str) |c| {
            if (c == robot_tile) {
                std.debug.print("Found robot at row {d} col {d}\n", .{ cpos.row, cpos.col });
                return .{ .robot_pos = cpos };
            }

            switch (c) {
                '\n' => {
                    cpos.row += 1;
                    cpos.col = 0;
                },
                else => cpos.col += 1,
            }
        }

        return StateError.RobotNotFound;
    }

    pub fn isRobotAt(self: *const State, row: usize, col: usize) bool {
        return row == self.robot_pos.row and
            col == self.robot_pos.col;
    }

    pub fn robotPos(self: *const State) Pos {
        return self.robot_pos;
    }

    pub fn moveRobotTo(self: *State, pos: Pos) void {
        self.robot_pos = pos;
    }

    pub fn deinit(self: *const State) void {
        // Nothing to deinit for now. Keep it for symetrie
        _ = self;
    }
};
