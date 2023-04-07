const std = @import("std");
const Color = @import("color.zig").Color;

pixel_buffer: [300]Color = undefined,
rgb: Color = .{ .raw = 0x0000 },

/// Fill buffer with the contents of rgb
pub fn handle_read_rgb(self: *@This(), buffer: []u8) u16 {
    if (buffer.len < 4) return 0;
    std.mem.writeIntLittle(u32, buffer[0..4], self.rgb.raw);
    return buffer[0..4].len;
}

/// copy the contents from the buffer into rgb
pub fn handle_write_rgb(self: *@This(), buffer: []u8) u16 {
    if (buffer.len < 4) return 0;
    self.rgb.raw = std.mem.readIntLittle(u32, buffer[0..4]);
    return buffer[0..4].len;
}

pub fn handle_read_nzr(self: *@This(), buffer: []u8) u16 {
    _ = buffer;
    _ = self;
    return 0;
}

pub fn handle_write_nzr(self: *@This(), buffer: []u8) u16 {
    _ = buffer;
    _ = self;
    return 0;
}
