const std = @import("std");
pub const ChannelState = @import("channel.zig");
pub const Mode = enum(u8) { disabled, pattern_start, pattern_stop, pattern_toggle, pattern_next, pattern_prev, _ };
pub const ChannelId = enum(u8) { channel1 = 1, channel2 = 2, _ };

mode: ?Mode = null,
channel_id: ?ChannelId = null,
channel: ?*ChannelState = null,
pattern: ?ChannelState.Pattern = null,

pub fn handle_read(self: *@This(), buffer: []u8) u16 {
    if (self.mode) |mode| {
        std.mem.writeIntLittle(u8, buffer[0..1], @enumToInt(mode));
    } else {
        std.mem.writeIntLittle(u8, buffer[0..1], 0);
    }

    if (self.channel_id) |channel_id| {
        std.mem.writeIntLittle(u8, buffer[1..2], @enumToInt(channel_id));
    } else {
        std.mem.writeIntLittle(u8, buffer[1..2], 0);
    }

    if (self.pattern) |channel_id| {
        std.mem.writeIntLittle(u8, buffer[2..3], @enumToInt(channel_id));
    } else {
        std.mem.writeIntLittle(u8, buffer[2..3], 0);
    }
    return 3;
}

pub fn handle_write(self: *@This(), buffer: []u8, channel1_state: *ChannelState, channel2_state: *ChannelState) u16 {
    if (buffer.len != 3) return 0;
    switch (@intToEnum(Mode, std.mem.readIntLittle(u8, buffer[0..1]))) {
        .disabled, .pattern_start, .pattern_stop, .pattern_toggle, .pattern_next, .pattern_prev => |mode| {
            self.mode = mode;
        },
        else => self.mode = null,
    }

    switch (@intToEnum(ChannelId, std.mem.readIntLittle(u8, buffer[1..2]))) {
        .channel1 => {
            self.channel = channel1_state;
            self.channel_id = .channel1;
        },
        .channel2 => {
            self.channel = channel2_state;
            self.channel_id = .channel2;
        },
        _ => {
            self.channel = null;
            self.channel_id = null;
        },
    }

    switch (@intToEnum(ChannelState.Pattern, std.mem.readIntLittle(u8, buffer[2..3]))) {
        .off, .rainbow, .snake => |pattern| self.pattern = pattern,
        else => self.pattern = null,
    }
    return 0;
}
