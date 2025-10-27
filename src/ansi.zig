const std = @import("std");

// https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b

pub const Ansi = struct {
    output: *std.Io.Writer,

    pub const Color = enum(u8) {
        black = 30,
        red = 31,
        green = 32,
        yellow = 33,
        blue = 34,
        magenta = 35,
        cyan = 36,
        white = 37,
        default = 39,
        reset = 0,
    };

    pub fn init(output: *std.Io.Writer) Ansi {
        return .{
            .output = output,
        };
    }

    pub fn flush(self: *const Ansi) !void {
        try self.output.flush();
    }

    pub fn resetColor(self: *const Ansi) !void {
        try self.setColor(Color.default);
        try self.flush();
    }

    pub fn resetAll(self: *const Ansi) !void {
        // Reset all modes
        try self.setColor(Color.reset);
        try self.flush();
    }

    pub fn clearScreen(self: *const Ansi) !void {
        // Erase entire screen
        try self.output.writeAll("\x1b[2J");

        // make cursor invisible
        try self.output.writeAll("\x1b[?25l");

        // Reset all modes
        try self.resetAll();
    }

    pub fn setColor(self: *const Ansi, color: Color) !void {
        try self.output.print("\x1b[{d}m", .{@intFromEnum(color)});
    }

    pub fn setBold(self: *const Ansi) !void {
        try self.output.print("\x1b[1m", .{});
    }

    pub fn setItalic(self: *const Ansi) !void {
        try self.output.print("\x1b[3m", .{});
    }

    pub fn setUnderline(self: *const Ansi) !void {
        try self.output.print("\x1b[4m", .{});
    }

    pub fn setReverse(self: *const Ansi) !void {
        try self.output.print("\x1b[7m", .{});
    }

    pub fn eraseLine(self: *const Ansi, line: usize) !void {
        try self.output.print("\x1b[{d};1H\x1b[2K", .{line});
    }

    pub fn moveCursorTo(self: *const Ansi, line: usize, column: usize) !void {
        try self.output.print("\x1b[{d};{d}H", .{ line, column });
    }

    pub fn writeCharNoFlush(self: *const Ansi, char: u8) !void {
        try self.output.print("{c}", .{char});
    }

    pub fn writeStrNoFlush(self: *const Ansi, str: []const u8, line: usize, column: usize) !void {
        // Move cursor to line
        try self.output.print("\x1b[{d};{d}H", .{ line, column });
        // Print the message
        try self.output.print("{s}", .{str});
    }

    pub fn writeStrAndFlush(self: *const Ansi, str: []const u8, line: usize, column: usize) !void {
        // Move cursor to line
        try self.output.print("\x1b[{d};{d}H", .{ line, column });
        // Print the message
        try self.output.print("{s}", .{str});
        // Move cursor to beginning of next line
        try self.output.print("\x1b[1E", .{});

        try self.flush();
    }
};
