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
    _ = n.init_pair(2, n.COLOR_BLACK, n.COLOR_GREEN);

    const max_x = n.getmaxx(stdscr) - 1;
    const max_y = n.getmaxy(stdscr) - 1;

    // As we are printing value calling C function we don't need to do any cast.
    _ = n.attron(n.COLOR_PAIR(1));
    _ = n.mvprintw(1, 1, "Screen size: %d x %d\n", max_y, max_x);

    // Let's print the four corners
    // A: Upper left is Y:0 X:0
    // B: Upper right is Y:0 X:max_x
    // C: Bottom left is Y:max_y X:0
    // D: Bottom right is Y:max_y X:max_x
    _ = n.attron(n.COLOR_PAIR(2));
    _ = n.mvprintw(0, 0, "A");
    _ = n.mvprintw(0, max_x, "B");
    _ = n.mvprintw(max_y, 0, "C");
    _ = n.mvprintw(max_y, max_x, "D");

    _ = n.refresh(); // Print it on the real screen
    _ = n.getch(); // Wait for user input
}
