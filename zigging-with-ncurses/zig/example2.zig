// https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/init.html#INITEX
// Example 2. Initialization Function Usage example
const std = @import("std");
const n = @cImport({
    @cInclude("ncurses.h");
});

pub fn main() void {
    _ = n.initscr();
    defer _ = n.endwin();

    _ = n.keypad(n.stdscr, true);
    _ = n.noecho();

    _ = n.printw("Type any character to see it in bold\n");
    const ch = n.getch();

    switch (ch) {
        n.KEY_F(1) => _ = n.printw("F1 Key pressed"),
        else => {
            _ = n.printw("The pressed key is ");
            _ = n.attron(n.A_BOLD);
            _ = n.printw("%c", ch);
            _ = n.attroff(n.A_BOLD);
        },
    }

    _ = n.refresh();
    _ = n.getch();
}
