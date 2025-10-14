const std = @import("std");
const Pos = @import("pos.zig").Pos;

const StateError = error{
    RobotNotFound,
    DuplicatedRobot,
};

const ItemError = error{
    UnknownItem,
};

const Item = union(enum) {
    key: u8,
    door: u8,
    box,
    robot,

    pub fn fromChar(c: u8) !Item {
        return switch (c) {
            'A'...'Z' => .{ .door = c },
            'a'...'z' => .{ .key = c },
            '&' => .box,
            '@' => .robot,
            else => ItemError.UnknownItem,
        };
    }

    pub fn toChar(self: Item) u8 {
        return switch (self) {
            .key => |k| k,
            .door => |d| d,
            .box => '&',
            .robot => '@',
        };
    }
};

const Robot = struct {
    const max_items: comptime_int = 5;

    pos: Pos,
    items: [max_items]?Item,
};

pub const State = struct {
    robot: Robot,
    items: std.AutoHashMap(Pos, Item), // Allow to get any item from a given position

    pub fn create(allocator: std.mem.Allocator, str: []const u8) !State {
        var pos = Pos{ .row = 0, .col = 0 };
        var robot_pos: ?Pos = null;

        var items = std.AutoHashMap(Pos, Item).init(allocator);

        for (str) |c| {
            switch (c) {
                '@' => {
                    if (robot_pos) |p| {
                        std.debug.print("Already found a robot at {d}x{d}\n", .{ p.row, p.col });
                        return StateError.DuplicatedRobot;
                    } else {
                        robot_pos = pos;
                        try items.put(pos, .robot);
                    }
                },
                'A'...'Z' => try items.put(pos, .{ .door = c }),
                'a'...'z' => try items.put(pos, .{ .key = c }),
                '&' => try items.put(pos, .box),
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

        // Before returning we print the items found all along the way
        var iter = items.iterator();

        while (iter.next()) |item| {
            std.debug.print("Found {c} at {d}x{d}\n", .{
                item.value_ptr.toChar(),
                item.key_ptr.row,
                item.key_ptr.col,
            });
        }

        return State{
            .robot = .{
                .pos = robot_pos orelse return StateError.RobotNotFound,
                .items = [_]?Item{null} ** Robot.max_items,
            },
            .items = items,
        };
    }

    pub fn getItemAt(self: *const State, pos: Pos) ?Item {
        return self.items.get(pos);
    }

    pub fn robotPos(self: *const State) Pos {
        return self.robot.pos;
    }

    pub fn moveRobotTo(self: *State, pos: Pos) !void {
        // Verifications should be done as the game logic, not here
        std.debug.print("robot moves from {d}x{d} to ", .{ self.robot.pos.row, self.robot.pos.col });
        _ = self.items.remove(self.robot.pos);
        try self.items.put(pos, .robot);
        self.robot.pos = pos;
        std.debug.print("{d}x{d}\n", .{ self.robot.pos.row, self.robot.pos.col });
    }

    pub fn destroy(self: *State) void {
        self.items.deinit();
    }
};
