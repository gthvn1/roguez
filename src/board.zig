const std = @import("std");

pub const Board = struct {
    b: [][]u8,

    pub fn create(allocator: std.mem.Allocator, str: []const u8) !Board {
        // We need to know the number of rows in [str] to be able to allocate [b] correctly.
        // So we do a first iteration to compute the number of rows.
        var str_it = std.mem.tokenizeSequence(u8, str, "\n");
        var row_count: usize = 0;
        while (str_it.next()) |_| {
            row_count += 1;
        }

        // Now we can allocate rows and go through each strings.
        var b = try allocator.alloc([]u8, row_count);
        var idx: usize = 0;
        str_it = std.mem.tokenizeSequence(u8, str, "\n");
        while (str_it.next()) |line| {
            b[idx] = try allocator.alloc(u8, line.len);
            std.mem.copyForwards(u8, b[idx], line);
            idx += 1;
        }

        return .{ .b = b };
    }

    pub fn destroy(self: *Board, allocator: std.mem.Allocator) void {
        for (self.b) |row| {
            allocator.free(row);
        }
        allocator.free(self.b);
    }

    pub fn print(self: *const Board) void {
        std.debug.print("\n", .{});
        for (self.b) |row| {
            for (row) |cell| {
                std.debug.print("{c} ", .{cell});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
};
