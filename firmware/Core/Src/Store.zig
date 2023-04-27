const builtin = @import("builtin");

pub const Key = enum(u8) {};

pub fn fetch(self: *@This(), comptime T: type, key: Key, default: T) T {
    _ = default;
    _ = key;
    _ = self;
}

pub fn put(self: *@This(), comptime T: type, key: Key, value: T) void {
    _ = value;
    _ = key;
    _ = self;
}
