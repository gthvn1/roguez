const std = @import("std");
const ncurses = @cImport({
    @cInclude("ncurses/ncurses.h");
});

pub fn main() void {
    _ = ncurses.initscr(); // Start curses mode
    _ = ncurses.printw("Hello World"); // Print Hello World
    _ = ncurses.refresh(); // Print it on the real screen
    _ = ncurses.getch(); // Wait for user input
    _ = ncurses.endwin(); // End curses mode
}
