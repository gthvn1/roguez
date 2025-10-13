const std = @import("std");
const Pos = @import("pos.zig").Pos;

const StateError = error{
    RobotNotFound,
};

pub const State = struct {
    robot: Pos,

    const robot_tile: u8 = '@';

    pub fn init(str: []const u8) !State {
        // TODO: really find the row and col in the map or null if not found.
        var pos = Pos{ .row = 0, .col = 0 };

        for (str) |c| {
            if (c == robot_tile) {
                std.debug.print("Found robot at row {d} col {d}\n", .{
                    pos.row,
                    pos.col,
                });
                return .{ .robot = pos };
            }

            switch (c) {
                '\n' => {
                    pos.row += 1;
                    pos.col = 0;
                },
                else => pos.col += 1,
            }
        }

        return StateError.RobotNotFound;
    }

    pub fn isRobotAt(self: *const State, pos: Pos) bool {
        return pos.row == self.robot.row and
            pos.col == self.robot.col;
    }

    pub fn robotPos(self: *const State) Pos {
        return self.robot;
    }

    pub fn moveRobotTo(self: *State, pos: Pos) void {
        self.robot = pos;
    }

    pub fn deinit(self: *const State) void {
        // Nothing to deinit for now. Keep it for symetrie
        _ = self;
    }
};
