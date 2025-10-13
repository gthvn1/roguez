const std = @import("std");
const Pos = @import("pos.zig").Pos;

const StateError = error{
    RobotNotFound,
    DuplicatedRobot,
};

const Item = union(enum) {
    Key: u8,
};

const Robot = struct {
    const max_items: comptime_int = 5;

    pos: Pos,
    items: [max_items]?Item,
};

pub const State = struct {
    robot: Robot,

    pub fn init(str: []const u8) !State {
        var pos = Pos{ .row = 0, .col = 0 };
        var robot_pos: ?Pos = null;

        for (str) |c| {
            switch (c) {
                '@' => {
                    std.debug.print("Found robot at row {d} col {d}\n", .{
                        pos.row,
                        pos.col,
                    });

                    if (robot_pos) |p| {
                        std.debug.print("Already found a robot at {d}x{d}\n", .{ p.row, p.col });
                        return StateError.DuplicatedRobot;
                    } else {
                        robot_pos = pos;
                    }
                },
                'A' => {
                    std.debug.print("TODO: Found A key at row {d} col {d}\n", .{
                        pos.row,
                        pos.col,
                    });
                },
                else => {},
            }

            switch (c) {
                '\n' => {
                    pos.row += 1;
                    pos.col = 0;
                },
                else => pos.col += 1,
            }
        }

        return State{
            .robot = .{
                .pos = robot_pos orelse return StateError.RobotNotFound,
                .items = [_]?Item{null} ** Robot.max_items,
            },
        };
    }

    pub fn isRobotAt(self: *const State, pos: Pos) bool {
        return pos.isEqualTo(self.robot.pos);
    }

    pub fn robotPos(self: *const State) Pos {
        return self.robot.pos;
    }

    pub fn moveRobotTo(self: *State, pos: Pos) void {
        self.robot.pos = pos;
    }

    pub fn deinit(self: *const State) void {
        // Nothing to deinit for now. Keep it for symetrie
        _ = self;
    }
};
