const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");
const handles = @import("handles.zig");
const hal = @import("stm32g4xx_hal.zig");
const rf69 = @import("rf69/src/main.zig");
var log_buffer: [1024]u8 = undefined;
const RadioMode = enum { Sender, Reciever };
const mode: RadioMode = .Reciever;
// const mode: RadioMode = .Sender;

pub const std_options = struct {
    // Set the log level to info
    pub const log_level = .info;
    // Define logFn to override the std implementation
    pub const logFn = log_to_uart2;
};

pub fn log_to_uart2(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    _ = scope;
    var printed = std.fmt.bufPrint(&log_buffer, format ++ "\r\n", args) catch @panic("log_to_uart2");
    _ = nosuspend c.HAL_UART_Transmit(handles.huart1, printed.ptr, @intCast(u16, printed.len), 1000);
    _ = nosuspend c.CDC_Transmit_FS(printed.ptr, @intCast(u16, printed.len));
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    @setCold(true);
    _ = error_return_trace;
    _ = return_address;
    switch (builtin.os.tag) {
        .freestanding => {
            var printed = std.fmt.bufPrint(&log_buffer, "PANIC: {s}\r\n", .{msg}) catch while (true) @breakpoint();
            _ = c.HAL_UART_Transmit(handles.huart1, printed.ptr, @intCast(u16, printed.len), 1000);
            while (true) @breakpoint();
        },
        else => @compileError("Only supported on freestanding"),
    }
}

export fn entry_error_handler() callconv(.C) void {
    @panic("unhandled error occurred");
}
var irq: bool = false;
/// Overrides the default from HAL
export fn HAL_GPIO_EXTI_Callback(gpio: u16) callconv(.C) void {
    std.log.info("gpio irq: {d}", .{gpio});
    irq = true;
}

export fn entry() callconv(.C) void {
    std.log.info("hello, from zig logger", .{});
    var spi1 = hal.spi.init(handles.hspi1);

    var nss = hal.gpio.initDefault(.A, .@"4");
    nss.write(.Set);

    var reset = hal.gpio.initDefault(.A, .@"2");

    var radio: rf69.Rf69 = undefined;
    if (mode == .Sender) {
        radio = rf69.Rf69.init(&spi1, &reset, &nss, 4);
    } else {
        radio = rf69.Rf69.init(&spi1, &reset, &nss, 4);
    }
    radio.reset();
    irq = false;
    var payload = [_]u8{ 'a', 'e', 'l', 'l', 'o', ' ', 'w', 'o', 'r', 'l', 'd' };
    std.log.info("hello, from zig logger", .{});

    // main loop
    while (true) {
        if (irq) {
            radio.service_interrupt();
        }
        if (mode == .Sender) {
            radio.send(0x02, &payload, false, false);
            hal.delay(1000);
        }
        if (radio.receive_done()) |packet| {
            std.log.info("payload: {s}", .{packet.payload});
            // std.log.info("payload: {x}", .{std.fmt.fmtSliceHexLower(packet.payload)});
            std.log.info("rssi={d}", .{radio.rssi});
        }
    }
}
