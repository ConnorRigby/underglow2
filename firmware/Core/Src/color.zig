const std = @import("std");
const testing = std.testing;
pub const Color = packed union {
    rgba: packed struct { r: u8, g: u8, b: u8, a: u8 },
    raw: u32,

    pub fn read_slice(slice: []u8) @This() {
        return @bitCast(@This(), std.mem.readIntNative(u32, slice[0..4]));
    }

    pub fn write_slice(color: @This(), slice: []u8) void {
        std.mem.writeIntNative(u32, slice[0..4], color.raw);
    }

    pub const red: @This() = .{ .rgba = .{ .r = 0xff, .g = 0, .b = 0, .a = 0xff } };
    pub const green: @This() = .{ .rgba = .{ .r = 0, .g = 0xff, .b = 0, .a = 0xff } };
    pub const blue: @This() = .{ .rgba = .{ .r = 0, .g = 0, .b = 0xff, .a = 0xff } };
    pub const off: @This() = .{ .rgba = .{ .r = 0, .g = 0, .b = 0x00, .a = 0x00 } };
    test {
        try testing.expectEqual(off.raw, 0x0);
        try testing.expectEqual(red.raw, 0xff0000ff);
        try testing.expectEqual(green.raw, 0xff00ff00);
        try testing.expectEqual(blue.raw, 0xffff0000);
    }
};

test {
    testing.refAllDecls(@This());
}
