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

    _ = n.initscr();
    defer _ = n.endwin();

    // if (!n.has_colors()) {
    //     std.debug.print("Your terminal does not support color\n", .{});
    //     return;
    // }

    _ = n.cbreak();
    _ = n.noecho();

    _ = n.start_color();

    _ = n.init_pair(1, n.COLOR_GREEN, n.COLOR_BLACK);
    _ = n.init_pair(2, n.COLOR_WHITE, n.COLOR_BLACK);
    _ = n.init_pair(3, n.COLOR_YELLOW, n.COLOR_BLACK);
    _ = n.init_pair(4, n.COLOR_BLUE, n.COLOR_BLACK);
    _ = n.init_pair(5, n.COLOR_CYAN, n.COLOR_BLACK);
    _ = n.init_pair(6, n.COLOR_MAGENTA, n.COLOR_BLACK);
    _ = n.init_pair(7, n.COLOR_RED, n.COLOR_BLACK);

    const maze_rows: c_int = @intCast(map.len);
    const maze_cols: c_int = @intCast(map[0].len);

    // Rows are from y = 0 to y = max_y
    // Cols are from x = 0 to x = max_x

    // We keep one line above the maze to print things
    if (n.LINES < maze_rows + 1) {
        std.debug.print("Your terminal has {d} rows, your map needs {d}\n", .{ n.LINES, maze_rows });
        return;
    }

    if (n.COLS < maze_cols) {
        std.debug.print("Your terminal has {d} cols, your map needs {d}\n", .{ n.COLS, maze_cols });
        return;
    }

    _ = n.mvprintw(0, 0, "Everything looks good");
    _ = n.refresh();

    // Create a new window for the maze
    const maze_win = n.newwin(maze_rows, maze_cols, 1, 0);
    defer _ = n.delwin(maze_win);

    for (map, 0..) |row, row_idx| {
        for (row, 0..) |c, col_idx| {
            const y: c_int = @intCast(row_idx);
            const x: c_int = @intCast(col_idx);
            const color: c_int = switch (c) {
                '@' => 7,
                'a'...'z' => 3,
                'A'...'Z' => 4,
                '#' => 5,
                '&' => 6,
                else => 1,
            };
            _ = n.wattron(maze_win, n.COLOR_PAIR(color));
            _ = n.mvwaddch(maze_win, y, x, c);
            _ = n.wattroff(maze_win, n.COLOR_PAIR(color));
        }
    }
    _ = n.wrefresh(maze_win);

    // TODO: create a window for debug
    _ = n.getch(); // Wait for user input
}
