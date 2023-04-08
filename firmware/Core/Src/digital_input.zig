const std = @import("std");
pub const ChannelState = @import("channel.zig");
pub const Mode = enum(u8) { disabled, _ };

mode: Mode = .disabled,
channel: ?*ChannelState = null,
patern: ChannelState.Patern = .off,

pub const Payload = packed struct { mode: Mode, channel: enum(u8) { channel1, channel2, _ }, patern: ChannelState.Patern };

pub fn handle_read(self: *@This(), buffer: []u8) u16 {
    _ = self;
    _ = buffer;
    return 0;
}

pub fn handle_write(self: *@This(), buffer: []u8) u16 {
    if (buffer.len != @sizeOf(Payload)) return 0;
    self.mode = std.mem.readIntLittle(Mode, buffer[0..1]);
    self.channel = std.mem.readIntLittle(Mode, buffer[1..2]);
    self.patern = std.mem.readIntLittle(Mode, buffer[2..3]);
    return 0;
}
