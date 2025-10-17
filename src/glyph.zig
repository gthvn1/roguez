const std = @import("std");

pub const Glyph = struct {
    bytes: [5]u8, // 4-byte UTF-8 + null terminator

    pub fn fromUtf8(s: []const u8) Glyph {
        var g = Glyph{
            .bytes = [_]u8{ 0, 0, 0, 0, 0 },
        };

        const len = @min(s.len, 4);
        std.mem.copyForwards(u8, g.bytes[0..len], s);
        return g;
    }

    pub fn fromChar(c: u8) Glyph {
        var g = Glyph{
            .bytes = [_]u8{ 0, 0, 0, 0, 0 },
        };

        g.bytes[0] = c;
        return g;
    }

    pub fn slice(self: *const Glyph) []const u8 {
        return std.mem.sliceTo(&self.bytes, 0);
    }
};
