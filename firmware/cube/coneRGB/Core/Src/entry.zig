const std = @import("std");

var log_buffer: [255]u8 = undefined;

pub const std_options = struct {
    // Set the log level to info
    pub const log_level = .info;
    // Define logFn to override the std implementation
    pub const logFn = log_to_uart2;
};

var huart2 = @extern(?*anyopaque, .{ .name = "huart2" });
extern fn HAL_UART_Transmit(?*anyopaque, [*c]const u8, u16, u32) c_int;

pub fn log_to_uart2(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    _ = scope;
    var printed = std.fmt.bufPrint(&log_buffer, format, args) catch return;
    _ = nosuspend HAL_UART_Transmit(huart2, printed.ptr, @intCast(u16, printed.len), 1000);
}

export fn entry() callconv(.C) void {
    std.log.info("hello, from {s}", .{"logger"});
}
