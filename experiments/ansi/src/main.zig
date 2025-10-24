const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);

    const stdout = &stdout_writer.interface;

    // https//gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
    // ESC     -> \x1b
    // Unicode -> \u001b

    try stdout.writeAll("\x1b[2J");

    // Move cursor to (1,1)
    try stdout.print("\x1b[1;1H", .{});

    // Print a red '@' for the player
    try stdout.print("\x1b[31m{s}\x1b[0m", .{"Hello, Sailor!"});

    // Move cursor to (2,3) and print a green '@'
    try stdout.print("\x1b[2;3H\x1b[32m@\x1b[0m", .{});

    // moves cursor to beginning of next line
    try stdout.print("\x1b[#E", .{});

    // Don't forget to flush
    try stdout.flush();
}
