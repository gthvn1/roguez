const std = @import("std");
const n = @cImport({
    @cInclude("ncurses.h");
});

// https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/
pub fn main() void {
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
    _ = n.attron(n.COLOR_PAIR(1));

    const max_x = n.getmaxx(stdscr);
    const max_y = n.getmaxy(stdscr);

    // As we are printing value calling C function we don't need to do any cast.
    _ = n.mvprintw(1, 1, "Screen size: %d x %d\n", max_y, max_x);
    _ = n.refresh(); // Print it on the real screen

    _ = n.getch(); // Wait for user input
}
