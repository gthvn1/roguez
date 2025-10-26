const std = @import("std");
const Map = @import("map.zig").Map;

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

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const GpaType = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GpaType{};
    var allocator = gpa.allocator();

    const m = try Map.of_string(&allocator, map_str);

    // We need to set the terminal in Raw mode to avoid pressing enter
    // TODO:
    //   - Should we restore the old_settings?
    set_raw_mode();

    try erase_screen(stdout);

    // - 1st line is the title
    try set_title(stdout);

    // - then we have the maze
    try draw_maze(stdout, &m);

    // - At line 1 + maze height + 1 we can print the position of the robot
    try stdout.print("\x1b[{d};1H", .{1 + m.height + 1});
    try stdout.print("Robot: line {d}, column {d}\n", .{ m.robot.line, m.robot.column });
    try stdout.flush();

    if (read_char()) |carlu| {
        try stdout.print("\nYou pressed: 0x{x}\n", .{carlu});
    } else {
        try stdout.print("\nFailed to read a char\n", .{});
    }
    try stdout.flush();
}

fn set_raw_mode() void {
    var settings: std.os.linux.termios = undefined;
    _ = std.os.linux.tcgetattr(0, &settings);

    // Disabling canonical mode allow the input to be immediatly available
    settings.lflag.ICANON = false;

    _ = std.os.linux.tcsetattr(0, std.posix.TCSA.NOW, &settings);
}

fn erase_screen(out: *std.Io.Writer) !void {
    try out.writeAll("\x1b[2J");

    // Reset all modes
    try out.print("\x1b[0m", .{});
}

fn set_title(out: *std.Io.Writer) !void {
    // Move cursor to (1,10)
    try out.print("\x1b[1;12H", .{});

    // Print a red , bold, underline, italic title
    try out.print("\x1b[1;3;4;31m{s}\x1b[0m", .{"Welcome to RogueZ !"});

    // Reset all modes
    try out.print("\x1b[0m", .{});
}

fn draw_maze(out: *std.Io.Writer, map: *const Map) !void {
    // https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
    // ESC     -> \x1b
    // Unicode -> \u001b

    // moves cursor to beginning of line 2
    try out.print("\x1b[2;1H", .{});

    // Print a yellow line
    for (map.map) |line| {
        for (line) |c| {
            switch (c) {
                '&' => {
                    // Yellow
                    try out.print("\x1b[1;33m", .{});
                    try out.print("{c}", .{c});
                },
                '$' => {
                    // Red
                    try out.print("\x1b[1;31m", .{});
                    try out.print("{c}", .{c});
                },
                '@' => {
                    // Green
                    try out.print("\x1b[1;32m", .{});
                    try out.print("{c}", .{c});
                },
                'a'...'z' => {
                    // Magenta
                    try out.print("\x1b[1;35m", .{});
                    try out.print("{c}", .{c});
                },
                'A'...'Z' => {
                    // Blue
                    try out.print("\x1b[1;34m", .{});
                    try out.print("{c}", .{c});
                },
                '.' => {
                    // Black
                    try out.print("\x1b[1;30m", .{});
                    try out.print(" ", .{});
                },
                '#' => {
                    // Cyan and don't use bold
                    try out.print("\x1b[0;36m", .{});
                    try out.print("{c}", .{c});
                },
                else => {
                    // Default
                    try out.print("\x1b[0;39m", .{});
                    try out.print("{c}", .{c});
                },
            }

            // Reset all modes
            try out.print("\x1b[0m", .{});
        }
        try out.print("\n", .{});
    }
    try out.print("\n", .{});

    // Don't forget to flush
    try out.flush();
}

fn read_char() ?u8 {
    var stdin_buffer: [1]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    const carlu: u8 = stdin.peekByte() catch return null;
    return carlu;
}
