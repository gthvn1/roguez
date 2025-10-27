const std = @import("std");
const Map = @import("map.zig").Map;
const Ansi = @import("ansi.zig").Ansi;

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

    var buf: [512:0]u8 = undefined; // Use to create quick string
    var m = try Map.of_string(&allocator, map_str);
    const term = Ansi.init(stdout);

    // We need to set the terminal in Raw mode to avoid pressing enter
    // TODO:
    //   - Should we restore the old_settings?
    set_raw_mode();

    try term.clearScreen();

    // - 1st line is the title
    const title_line: comptime_int = 1;
    try term.setColor(Ansi.Color.red);
    try term.writeStrAndFlush("Welcome to RogueZ", title_line, 12);
    try term.resetColor();

    // - At line 1 + maze height + 1 we can print the position of the robot
    const status_line = 1 + m.height + 1;

    while (true) {
        // Start by drawing the maze
        try draw_maze(&term, &m);

        // On the status line print the position of the robot
        const str = try std.fmt.bufPrint(&buf, "Robot: line {d}, column {d}\n", .{
            m.robot.line,
            m.robot.column,
        });
        try term.writeStrAndFlush(str, status_line, 1);

        // On status line + 1 print the help
        try term.writeStrAndFlush("HELP: use arrows keys to move, 'q' to quit", status_line + 1, 1);

        // Erase status line + 2 that will be the debug line
        // Note: as writeStrAndFlush goes to the next line it will also erase the echo of the read_char.
        try term.eraseLine(status_line + 2);

        if (read_char()) |carlu| {
            switch (carlu) {
                'h', 0x44 => m.robot.column -= 1,
                'j', 0x42 => m.robot.line += 1,
                'k', 0x41 => m.robot.line -= 1,
                'l', 0x43 => m.robot.column += 1,
                'q' => {
                    try term.writeStrAndFlush("Bye !!!", status_line + 2, 1);
                    break;
                },
                else => {
                    const s = try std.fmt.bufPrint(&buf, "DEBUG: You pressed {c}", .{carlu});
                    try term.writeStrAndFlush(s, status_line + 2, 1);
                },
            }
        } else {
            try term.writeStrAndFlush("Failed to read a char", status_line + 2, 1);
        }
    }

    try term.resetAll();
}

fn set_raw_mode() void {
    var settings: std.os.linux.termios = undefined;
    _ = std.os.linux.tcgetattr(0, &settings);

    // Disabling canonical mode allow the input to be immediatly available
    settings.lflag.ICANON = false;

    _ = std.os.linux.tcsetattr(0, std.posix.TCSA.NOW, &settings);
}

fn draw_maze(term: *const Ansi, map: *const Map) !void {
    // Move cursor to beginning of line 2, there is the title on line 1.
    try term.moveCursorTo(2, 1);

    // Print a yellow line
    for (map.map) |line| {
        for (line) |c| {
            switch (c) {
                '&' => {
                    try term.setColor(Ansi.Color.yellow);
                    try term.writeCharNoFlush(c);
                },
                '$' => {
                    try term.setColor(Ansi.Color.red);
                    try term.writeCharNoFlush(c);
                },
                '@' => {
                    // Robot will be drawn later
                    try term.writeCharNoFlush(' ');
                },
                'a'...'z' => {
                    try term.setColor(Ansi.Color.magenta);
                    try term.writeCharNoFlush(c);
                },
                'A'...'Z' => {
                    try term.setColor(Ansi.Color.blue);
                    try term.writeCharNoFlush(c);
                },
                '.' => {
                    try term.setColor(Ansi.Color.black);
                    try term.writeCharNoFlush(c);
                },
                '#' => {
                    try term.setColor(Ansi.Color.cyan);
                    try term.writeCharNoFlush(c);
                },
                else => {
                    try term.resetColor();
                    try term.writeCharNoFlush(c);
                },
            }
        }

        try term.writeCharNoFlush('\n');
    }

    // Draw the robot in green. Not that line and color in ANSI starts from 1. While
    // robot start from 0.
    try term.moveCursorTo(map.robot.line + 1, map.robot.column + 1);
    try term.setColor(Ansi.Color.green);
    try term.writeCharNoFlush('@');

    // Reset all also does the flush
    try term.resetAll();
}

fn read_char() ?u8 {
    var stdin_buffer: [1]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    const carlu: u8 = stdin.peekByte() catch return null;
    return carlu;
}
