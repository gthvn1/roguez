const std = @import("std");
const n = @cImport({
    @cInclude("ncurses.h");
});

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

//
// rows -> [ ptr  ptr  ptr ptr ] => [] []const u8
//            |
//            v
//      [u8 u8 u8 ...] => []const u8
fn map_of_string(allocator: *std.mem.Allocator, str: []const u8) ![][]const u8 {
    var lines_iter = std.mem.splitAny(u8, str, "\n");

    // We need to know the numbers of row and the number of columns.
    // So we do a first iteration to compute this
    var rows: usize = 0;
    while (lines_iter.next()) |_| {
        rows += 1;
    }

    if (rows == 0) {
        unreachable("empty map is not expected\n");
    }

    var map = try allocator.alloc([]const u8, rows);

    lines_iter = std.mem.splitAny(u8, str, "\n");
    rows = 0;
    while (lines_iter.next()) |s| {
        const r = try allocator.alloc(u8, s.len);
        std.mem.copyForwards(u8, r, s);
        map[rows] = r;
        rows += 1;
    }

    return map;
}

fn free_map(allocator: *std.mem.Allocator, map: [][]const u8) void {
    for (map) |row| {
        allocator.free(row);
    }
    allocator.free(map);
}

// https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/
pub fn main() !void {
    const GpaType = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GpaType{};
    var allocator = gpa.allocator();

    const map = try map_of_string(&allocator, map_str);
    defer free_map(&allocator, map);

    const stdscr = n.initscr();
    // In case of errors a message is written to stderr and initscr
    // exists.
    defer _ = n.endwin();

    if (!n.has_colors()) {
        std.debug.print("Your terminal does not support color\n", .{});
        return;
    }

    _ = n.start_color();

    _ = n.init_pair(1, n.COLOR_GREEN, n.COLOR_BLACK);
    _ = n.init_pair(2, n.COLOR_BLACK, n.COLOR_GREEN);
    _ = n.init_pair(3, n.COLOR_BLACK, n.COLOR_YELLOW);
    _ = n.init_pair(4, n.COLOR_BLACK, n.COLOR_BLUE);
    _ = n.init_pair(5, n.COLOR_BLACK, n.COLOR_CYAN);
    _ = n.init_pair(6, n.COLOR_BLACK, n.COLOR_MAGENTA);
    _ = n.init_pair(7, n.COLOR_BLACK, n.COLOR_RED);

    const max_x = n.getmaxx(stdscr);
    const max_y = n.getmaxy(stdscr);

    const max_row: c_int = @intCast(map.len);
    const max_col: c_int = @intCast(map[0].len);

    // Rows are from y = 0 to y = max_y
    // Cols are from x = 0 to x = max_x
    if (max_y < max_row) {
        std.debug.print("Your terminal has {d} rows, your map needs {d}\n", .{ max_y, max_row });
        return;
    }

    if (max_x < max_col) {
        std.debug.print("Your terminal has {d} cols, your map needs {d}\n", .{ max_x, max_col });
        return;
    }

    for (map, 0..) |row, row_idx| {
        for (row, 0..) |c, col_idx| {
            const y: c_int = @intCast(row_idx);
            const x: c_int = @intCast(col_idx);
            _ = switch (c) {
                '@' => n.attron(n.COLOR_PAIR(7)),
                'a'...'z' => n.attron(n.COLOR_PAIR(3)),
                'A'...'Z' => n.attron(n.COLOR_PAIR(4)),
                '#' => n.attron(n.COLOR_PAIR(5)),
                '&' => n.attron(n.COLOR_PAIR(6)),
                else => n.attron(n.COLOR_PAIR(1)),
            };
            _ = n.mvprintw(y, x, "%c", c);
        }
    }

    _ = n.attron(n.COLOR_PAIR(2));
    _ = n.mvprintw(max_row + 1, 0, "DEBUG: max_row = %d", max_row);
    _ = n.mvprintw(max_row + 2, 0, "DEBUG: max_col = %d", max_col);
    _ = n.mvprintw(max_row + 3, 0, "DEBUG: max_y   = %d", max_y);
    _ = n.mvprintw(max_row + 4, 0, "DEBUG: max_x   = %d", max_x);

    _ = n.refresh();
    _ = n.getch(); // Wait for user input
}
