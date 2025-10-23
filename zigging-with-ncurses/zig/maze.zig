const std = @import("std");
const n = @cImport({
    @cInclude("ncursesw/ncurses.h");
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

const MapError = error{
    EmptyMap,
    RobotNotFound,
};

const Map = struct {
    map: [][]const u8,
    robot_row: c_int,
    robot_col: c_int,

    //
    // rows -> [ ptr  ptr  ptr ptr ] => [] []const u8
    //            |
    //            v
    //      [u8 u8 u8 ...] => []const u8
    pub fn of_string(allocator: *std.mem.Allocator, str: []const u8) !Map {
        var robot_row: ?c_int = null;
        var robot_col: ?c_int = null;

        var lines_iter = std.mem.splitAny(u8, str, "\n");

        // We need to know the numbers of row and the number of columns.
        // So we do a first iteration to compute this
        var rows: usize = 0;
        while (lines_iter.next()) |l| {
            // Check if the robot is on this line
            if (std.mem.indexOfScalar(u8, l, '@')) |col| {
                robot_row = @intCast(rows);
                robot_col = @intCast(col);
            }
            rows += 1;
        }

        if (rows == 0) {
            return MapError.EmptyMap;
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

        if (robot_row) |rr| {
            if (robot_col) |rc| {
                return .{
                    .map = map,
                    .robot_row = rr,
                    .robot_col = rc,
                };
            }
        }

        return MapError.RobotNotFound;
    }

    pub fn free(self: *const Map, allocator: *std.mem.Allocator) void {
        for (self.map) |row| {
            allocator.free(row);
        }
        allocator.free(self.map);
    }
};

// https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/
pub fn main() !void {
    const GpaType = std.heap.GeneralPurposeAllocator(.{});
    var gpa = GpaType{};
    var allocator = gpa.allocator();

    const m = try Map.of_string(&allocator, map_str);
    defer m.free(&allocator);

    _ = n.initscr();
    defer _ = n.endwin();

    // if (!n.has_colors()) {
    //     std.debug.print("Your terminal does not support color\n", .{});
    //     return;
    // }

    _ = n.cbreak();
    _ = n.noecho();
    _ = n.keypad(n.stdscr, true);

    _ = n.start_color();

    _ = n.init_pair(1, n.COLOR_BLACK, n.COLOR_GREEN);
    _ = n.init_pair(2, n.COLOR_WHITE, n.COLOR_BLACK);
    _ = n.init_pair(3, n.COLOR_YELLOW, n.COLOR_BLACK);
    _ = n.init_pair(4, n.COLOR_BLUE, n.COLOR_BLACK);
    _ = n.init_pair(5, n.COLOR_CYAN, n.COLOR_BLACK);
    _ = n.init_pair(6, n.COLOR_MAGENTA, n.COLOR_BLACK);
    _ = n.init_pair(7, n.COLOR_RED, n.COLOR_BLACK);

    const maze_rows: c_int = @intCast(m.map.len);
    const maze_cols: c_int = @intCast(m.map[0].len);

    // Rows are from y = 0 to y = max_y
    // Cols are from x = 0 to x = max_x

    // We keep two lines above the maze to print things
    if (n.LINES < maze_rows + 2) {
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
    const maze_win = n.newwin(maze_rows, maze_cols, 2, 0) orelse unreachable;
    defer _ = n.delwin(maze_win);

    // TODO: create a window for debug

    // We just need to update the position of the robot in the main loop
    var cur_row = m.robot_row;
    var cur_col = m.robot_col;
    var next_row = m.robot_row;
    var next_col = m.robot_col;

    draw_map(maze_win, m);

    main_loop: while (true) {
        update_robot(maze_win, cur_row, cur_col, next_row, next_col);

        cur_row = next_row;
        cur_col = next_col;

        switch (n.getch()) {
            n.KEY_F(1), 'q' => break :main_loop,
            n.KEY_LEFT => next_col -= 1,
            n.KEY_RIGHT => next_col += 1,
            n.KEY_UP => next_row -= 1,
            n.KEY_DOWN => next_row += 1,
            else => continue :main_loop,
        }
    }
}

fn draw_map(win: *n.struct__win_st, m: Map) void {
    for (m.map, 0..) |row, row_idx| {
        for (row, 0..) |c, col_idx| {
            const y: c_int = @intCast(row_idx);
            const x: c_int = @intCast(col_idx);
            switch (c) {
                '#' => draw_cell(win, ' ', 1, y, x),
                'a'...'z' => draw_cell(win, c, 2, y, x),
                'A'...'Z' => draw_cell(win, c, 3, y, x),
                '&' => draw_cell(win, '#', 4, y, x),
                else => continue,
            }
        }
    }

    _ = n.wrefresh(win);
}

fn update_robot(win: *n.struct__win_st, row_from: c_int, col_from: c_int, row_to: c_int, col_to: c_int) void {
    // TODO: currently we just erase the old character.
    draw_cell(win, ' ', 5, row_from, col_from);
    draw_cell(win, '@', 5, row_to, col_to);
    _ = n.wrefresh(win);
}

fn draw_cell(win: *n.struct__win_st, char: u8, color: c_int, row: c_int, col: c_int) void {
    _ = n.wattron(win, n.COLOR_PAIR(color));
    _ = n.mvwaddch(win, row, col, char);
    _ = n.wattroff(win, n.COLOR_PAIR(color));
}
