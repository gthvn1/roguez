const std = @import("std");

pub const State = struct {
    pub fn create(allocator: std.mem.Allocator, str: []const u8) !State {
        // TODO: really create a state
        _ = allocator;
        _ = str;
        return .{};
    }

    pub fn destroy(self: *const State, allocator: std.mem.Allocator) void {
        // TODO: really destroy a state
        _ = allocator;
        _ = self;
    }
};
