// https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/windows.html#LETBEWINDOW
// Example 7. Window Border example
const std = @import("std");
const n = @cImport({
    @cInclude("ncursesw/ncurses.h");
});

pub fn main() void {
    _ = n.initscr();
    defer _ = n.endwin();

    _ = n.cbreak(); // Line buffering disabled
    _ = n.noecho(); // Don't echo key strokes
    _ = n.keypad(n.stdscr, true); // I need that nifty F1

    const height: c_int = 3;
    const width: c_int = 10;
    // Calculating for a center placement of the window
    var starty: c_int = @divTrunc(n.LINES - height, 2);
    var startx: c_int = @divTrunc(n.COLS - width, 2);

    _ = n.printw("Press F1 to exit");
    _ = n.refresh();

    var my_win: *n.struct__win_st = create_newwin(
        height,
        width,
        starty,
        startx,
    ) orelse return;

    main_loop: while (true) {
        switch (n.getch()) {
            n.KEY_F(1) => break :main_loop,
            n.KEY_LEFT => startx -= 1,
            n.KEY_RIGHT => startx += 1,
            n.KEY_UP => starty -= 1,
            n.KEY_DOWN => starty += 1,
            else => continue :main_loop,
        }
        destroy_win(my_win);
        my_win = create_newwin(height, width, starty, startx) orelse return;
    }

    destroy_win(my_win);
}

fn create_newwin(height: c_int, width: c_int, starty: c_int, startx: c_int) ?*n.struct__win_st {
    const local_win = n.newwin(height, width, starty, startx);

    _ = n.box(local_win, 0, 0);
    // 0, 0 gives default characters for the vertical and horizontal lines
    _ = n.wrefresh(local_win); // show that box

    return local_win;
}

fn destroy_win(local_win: *n.struct__win_st) void {
    // box(local_win, ' ', ' '); : This won't produce the desired
    // result of erasing the window. It will leave it's four corners
    // and so an ugly remnant of window.
    _ = n.wborder(local_win, ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ');
    // The parameters taken are
    // 1. win: the window on which to operate
    // 2. ls: character to be used for the left side of the window
    // 3. rs: character to be used for the right side of the window
    // 4. ts: character to be used for the top side of the window
    // 5. bs: character to be used for the bottom side of the window
    // 6. tl: character to be used for the top left corner of the window
    // 7. tr: character to be used for the top right corner of the window
    // 8. bl: character to be used for the bottom left corner of the window
    // 9. br: character to be used for the bottom right corner of the window
    _ = n.wrefresh(local_win);
    _ = n.delwin(local_win);
}
