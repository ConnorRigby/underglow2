const std = @import("std");
const Color = @import("color.zig").Color;

pub const Pattern = enum(u8) { off, rainbow, snake, fill, _ };

pub const Rainbow = @import("patterns/rainbow.zig");
pub const Snake = @import("patterns/snake.zig");
pub const Fill = @import("patterns/fill.zig");
pub const PatternState = union(Pattern) {
    off: void,
    rainbow: Rainbow,
    snake: Snake,
    fill: Fill,
};
pub const OperationState = enum { start, work, complete };

operation_state: OperationState = .start,
pixel_buffer: [10]Color = undefined,
rgb: Color = .{ .raw = 0x0000 },
pattern: ?PatternState = null,
stack_index: usize = std.math.maxInt(usize),
stack: [3]?PatternState = .{ null, null, null },
trigger: bool = false,

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

pub fn pattern_push(self: *@This(), pattern: Pattern) void {
    self.stack_index +%= 1;
    self.stack[self.stack_index] = switch (pattern) {
        .off => null,
        .rainbow => .{ .rainbow = .{} },
        .snake => .{ .snake = .{} },
        .fill => .{ .fill = .{} },
        else => unreachable,
    };
    self.operation_state = .start;
}

pub fn pattern_pop(self: *@This()) void {
    self.stack[self.stack_index] = null;
    self.stack_index -%= 1;
    self.operation_state = .start;
}

pub fn pattern_prev(self: *@This()) void {
    _ = self;
}

pub fn pattern_next(self: *@This()) void {
    _ = self;
}

pub fn pattern_trigger(self: *@This(), pattern: Pattern) void {
    self.pattern_push(pattern);
    self.operation_state = .start;
    self.trigger = true;
}

pub fn get_current_pattern(self: *@This()) ?Pattern {
    if (self.stack_index < self.stack.len) if (self.stack[self.stack_index]) |pattern| switch (pattern) {
        inline .off, .rainbow, .snake, .fill => return @as(Pattern, pattern),
    };
    if (self.pattern) |pattern| switch (pattern) {
        inline .off, .rainbow, .snake, .fill => return @as(Pattern, pattern),
    } else return null;

    return null;
}

pub fn state_run(self: *@This()) void {
    switch (self.operation_state) {
        .start, .work => self.state_work(),
        .complete => if (self.trigger) {
            self.pattern_pop();
            self.trigger = false;
            self.operation_state = .start;
        } else {
            self.trigger = false;
            self.operation_state = .start;
        },
    }
}

fn state_work(self: *@This()) void {
    // std.log.info("stackptr={d} stack[{d}-1] = {any}", .{ self.stack_index, self.stack_index, self.stack[self.stack_index] });
    if (self.stack_index < self.stack.len) if (self.stack[self.stack_index]) |pattern| switch (pattern) {
        .off => std.mem.set(Color, &self.pixel_buffer, Color.off),
        .rainbow => {
            self.operation_state = self.stack[self.stack_index].?.rainbow.state_run(&self.pixel_buffer);
            return;
        },
        .snake => {
            self.operation_state = self.stack[self.stack_index].?.snake.state_run(&self.pixel_buffer);
            return;
        },
        .fill => {
            self.operation_state = self.stack[self.stack_index].?.fill.state_run(&self.pixel_buffer);
            return;
        },
        else => return,
    };
    if (self.pattern) |pattern| switch (pattern) {
        .off => std.mem.set(Color, &self.pixel_buffer, Color.off),
        .rainbow => self.operation_state = self.pattern.?.rainbow.state_run(&self.pixel_buffer),
        .snake => self.operation_state = self.pattern.?.snake.state_run(&self.pixel_buffer),
        .fill => self.operation_state = self.pattern.?.fill.state_run(&self.pixel_buffer),
        else => return,
    } else return;
}
