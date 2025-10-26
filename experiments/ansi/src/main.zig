const std = @import("std");

pub const map_str: []const u8 =
    \\########################################
    \\#.......#........................&.....#
    \\#..a....#..........................&...#
    \\#.......#........&..............@......#
    \\#.......E.........................#....#
    \\####A####.........................#....#
    \\#.......#.......&......................#
    \\#.......#......#.#....b..........f.....#
    \\#...$...#......#.#........c............#
    \\#.......#......#e#............d........#
    \\#########......###.....................#
    \\#......................................#
    \\#......................................#
    \\########################################
;

const Pos = struct {
    line: usize,
    column: usize,
};

const MapError = error{
    Empty,
    RobotNotFound,
};

const Map = struct {
    robot: Pos,
    map: [][]const u8,
    allocator: *std.mem.Allocator,

    pub fn of_string(allocator: *std.mem.Allocator, str: []const u8) !Map {
        var robot: ?Pos = null;

        var line_iter = std.mem.splitAny(u8, str, "\n");

        // We need to know the numbers of lines and the number of columns.
        // So we do a first iteration to compute this. In the same time we will
        // try to find the robot.
        var lines: usize = 0;
        while (line_iter.next()) |l| {
            // Check if the robot is on this line
            if (std.mem.indexOfScalar(u8, l, '@')) |col| {
                robot = .{
                    .line = @intCast(lines),
                    .column = @intCast(col),
                };
            }
            lines += 1;
        }

        if (lines == 0) {
            return MapError.Empty;
        }

        if (robot) |r| {
            var map = try allocator.alloc([]const u8, lines);

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

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const GpaType = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GpaType{};
    var allocator = gpa.allocator();

    const m = try Map.of_string(&allocator, map_str);
    // https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
    // ESC     -> \x1b
    // Unicode -> \u001b

    try stdout.writeAll("\x1b[2J");

    // Move cursor to (1,10)
    try stdout.print("\x1b[1;12H", .{});

    // Print a red , bold, underline, italic title
    try stdout.print("\x1b[1;3;4;31m{s}\x1b[0m", .{"Welcome to RogueZ !"});

    // moves cursor to beginning of next line
    try stdout.print("\x1b[#E", .{});

    // Print a yellow line
    for (m.map) |line| {
        for (line) |c| {
            switch (c) {
                '&' => {
                    // Yellow
                    try stdout.print("\x1b[1;33m", .{});
                    try stdout.print("{c}", .{c});
                },
                '$' => {
                    // Red
                    try stdout.print("\x1b[1;31m", .{});
                    try stdout.print("{c}", .{c});
                },
                '@' => {
                    // Green
                    try stdout.print("\x1b[1;32m", .{});
                    try stdout.print("{c}", .{c});
                },
                'a'...'z' => {
                    // Magenta
                    try stdout.print("\x1b[1;35m", .{});
                    try stdout.print("{c}", .{c});
                },
                'A'...'Z' => {
                    // Blue
                    try stdout.print("\x1b[1;34m", .{});
                    try stdout.print("{c}", .{c});
                },
                '.' => {
                    // Black
                    try stdout.print("\x1b[1;30m", .{});
                    try stdout.print(" ", .{});
                },
                '#' => {
                    // Cyan and don't use bold
                    try stdout.print("\x1b[0;36m", .{});
                    try stdout.print("{c}", .{c});
                },
                else => {
                    // Default
                    try stdout.print("\x1b[0;39m", .{});
                    try stdout.print("{c}", .{c});
                },
            }

            // Reset all modes
            try stdout.print("\x1b[0m", .{});
        }
        try stdout.print("\n", .{});
    }
    try stdout.print("\n", .{});

    // Don't forget to flush
    try stdout.flush();
}
