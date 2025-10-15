const std = @import("std");

const ItemError = error{
    UnknownItem,
};

pub const Item = union(enum) {
    key: u8,
    door: u8,
    box,
    robot,

    pub fn fromChar(c: u8) !Item {
        return switch (c) {
            'a'...'z' => .{ .key = c },
            'A'...'Z' => .{ .door = c },
            '&' => .box,
            '@' => .robot,
            else => ItemError.UnknownItem,
        };
    }

    pub fn toChar(self: Item, buf: *[5]u8) *[5]u8 {
        // https://symbl.cc/en/unicode-table
        // Unicode requires at most 4 bytes for encoding. So to have a null
        // terminated string we need 5 bytes.
        const robot = "\u{26D1}";
        const box = "\u{26C1}";

        std.mem.copyForwards(u8, buf, &[_]u8{ 0, 0, 0, 0, 0 });

        switch (self) {
            .key => |k| buf[0] = k,
            .door => |d| buf[0] = d,
            .box => std.mem.copyForwards(u8, buf, box),
            .robot => std.mem.copyForwards(u8, buf, robot),
        }

        return buf;
    }
};
