const std = @import("std");

const Pos = struct {
    line: usize,
    column: usize,
};

const MapError = error{
    Empty,
    RobotNotFound,
};

pub const Map = struct {
    robot: Pos,
    map: [][]const u8,
    width: usize, // The number of columns starting from 0
    height: usize, // The number of lines starting from 0
    allocator: *std.mem.Allocator,

    pub fn of_string(allocator: *std.mem.Allocator, str: []const u8) !Map {
        var robot: ?Pos = null;

        var line_iter = std.mem.splitAny(u8, str, "\n");

        // We need to know the numbers of lines and the number of columns.
        // So we do a first iteration to compute this. In the same time we will
        // try to find the robot.
        var height: usize = 0;
        var width: usize = 0;

        while (line_iter.next()) |line| {
            // Check if the robot is on this line
            if (std.mem.indexOfScalar(u8, line, '@')) |col| {
                robot = .{
                    .line = @intCast(height),
                    .column = @intCast(col),
                };
            }
            // Always update width it is not that important.
            // All lines should have the same len.
            width = line.len;
            height += 1;
        }

        if (height == 0) {
            return MapError.Empty;
        }

        if (robot) |r| {
            var map = try allocator.alloc([]const u8, height);

            // Now we can do the second iteration
            line_iter = std.mem.splitAny(u8, str, "\n");
            var current_line: usize = 0;
            while (line_iter.next()) |s| {
                const l = try allocator.alloc(u8, s.len);
                std.mem.copyForwards(u8, l, s);
                map[current_line] = l;
                current_line += 1;
            }

            return .{
                .map = map,
                .height = height,
                .width = height,
                .robot = r,
                .allocator = allocator,
            };
        } else {
            return MapError.RobotNotFound;
        }
    }

    pub fn free(self: *const Map) void {
        for (self.map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.map);
    }
};
