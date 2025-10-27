const std = @import("std");
const r = @import("roguez");
const Ansi = r.Ansi;

pub fn main() !void {
    const GPAtype = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GPAtype{};
    const allocator = gpa.allocator();
    const map = @import("map.zig").map;

    // We need to set the terminal in Raw mode to avoid pressing enter
    // TODO: Should we restore the old_settings?
    var settings: std.os.linux.termios = undefined;
    _ = std.os.linux.tcgetattr(0, &settings);

    // Disabling canonical mode allow the input to be immediatly available
    settings.lflag.ICANON = false;

    _ = std.os.linux.tcsetattr(0, std.posix.TCSA.NOW, &settings);
    // we can now read character without pressing enter

    // Prepare the output
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const term = Ansi.init(stdout);

    var g = try r.Game.create(allocator, map);
    defer g.destroy(allocator);

    try term.clearScreen();

    // First line is the title
    var current_line: usize = 1;
    try term.setColor(Ansi.Color.red);
    try term.setBold();
    try term.setItalic();
    try term.writeStrAndFlush("Welcome to RogueZ", current_line, 12);
    try term.resetAll();

    // Then comes the menu
    const help = [_][]const u8{
        " 'q' to quit",
        " 'h' to move left",
        " 'j' to move down",
        " 'k' to move up",
        " 'l' to move right",
        "You can use arrows to move",
    };

    // Print the header of the help
    current_line += 1;
    try term.setColor(Ansi.Color.white);
    try term.setBold();
    try term.setItalic();
    try term.setUnderline();
    try term.writeStrAndFlush("Help", current_line, 1);

    // Now the sub item of the help
    try term.resetAll();
    try term.setColor(Ansi.Color.white);

    for (help) |line| {
        current_line += 1;
        try term.writeStrAndFlush(line, current_line, 1);
    }

    // Reset things and update current line
    try term.resetAll();
    current_line += 2; // Add an extra line for clarity

    while (true) {
        try g.print(&term, current_line);
        switch (r.readChar()) {
            'h', 0x44 => try g.moveRobot(r.Dir.left),
            'j', 0x42 => try g.moveRobot(r.Dir.down),
            'k', 0x41 => try g.moveRobot(r.Dir.up),
            'l', 0x43 => try g.moveRobot(r.Dir.right),
            'q' => break,
            else => continue,
        }
    }
}
