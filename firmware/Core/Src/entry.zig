const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");
const p = @import("pin_names.zig");
const handles = @import("handles.zig");

const hal = @import("stm32g4xx_hal.zig");
const rf69 = @import("lib/rf69/src/main.zig");

var log_buffer: [1024]u8 = undefined;

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

var irq_ready: bool = false;

export fn HAL_GPIO_EXTI_Callback(gpio: u16) callconv(.C) void {
    std.log.info("gpio irq: {d}", .{gpio});
    if (gpio == 4) irq_ready = true;
}

/// Main entry point, called from main.c
export fn entry() callconv(.C) void {
    var tx = hal.gpio.init(.{ .B = .{ .pin = .@"6", .mode = .OutputPushPull, .pull = .Down, .speed = .Low } });
    tx.write(.Set);

    var rx = hal.gpio.init(.{ .B = .{ .pin = .@"7", .mode = .OutputPushPull, .pull = .Down, .speed = .Low } });
    rx.write(.Set);

    var ch1_en = hal.gpio.init(.{ .A = .{ .pin = .@"3", .mode = .OutputPushPull, .pull = .Down, .speed = .Low } });
    ch1_en.write(.Reset);

    var ch1_r = hal.gpio.init(.{ .A = .{ .pin = .@"7", .mode = .OutputPushPull, .pull = .Down, .speed = .Low } });
    ch1_r.write(.Set);

    var ch2_en = hal.gpio.init(.{ .A = .{ .pin = .@"2", .mode = .OutputPushPull, .pull = .Down, .speed = .Low } });
    ch2_en.write(.Reset);

    var ch2_r = hal.gpio.init(.{ .B = .{ .pin = .@"1", .mode = .OutputPushPull, .pull = .Down, .speed = .Low } });
    ch2_r.write(.Set);
    var ch2_g = hal.gpio.init(.{ .C = .{ .pin = .@"11", .mode = .OutputPushPull, .pull = .Down, .speed = .Low } });
    ch2_g.write(.Set);

    var spi1 = hal.spi.init(handles.hspi1);

    var nss = hal.gpio.initDefault(.A, .@"4");
    nss.write(.Set);

    var reset = hal.gpio.initDefault(.B, .@"0");

    var radio = rf69.Rf69.init(&spi1, &reset, &nss, 4);
    radio.reset();
    var payload = [_]u8{ 'a', 'e', 'l', 'l', 'o', ' ', 'w', 'o', 'r', 'l', 'd' };
    radio.send(0x02, &payload, false, false);

    // var di1 = hal.gpio.initDefault(.C, .@"6");
    // var di2 = hal.gpio.initDefault(.A, .@"8");
    // var di3 = hal.gpio.initDefault(.A, .@"9");
    // var di4 = hal.gpio.initDefault(.A, .@"15");

    while (true) {
        if (irq_ready) {
            rx.write(.Reset);
            radio.service_interrupt();
            rx.write(.Set);
            irq_ready = false;
        }
        if (radio.receive_done()) |packet| {
            std.log.info("received packet: {any}", .{packet});
            // std.log.info("payload: {x}", .{std.fmt.fmtSliceHexLower(packet.payload)});
            // std.log.info("payload: {s}", .{packet.payload});
            std.log.info("rssi={d}", .{radio.rssi});
            // var payload = [_]u8{'h'};
            radio.send(0x03, &payload, false, false);
        }
        hal.delay(250);
        // std.log.info("di1={any} di2={any} di3={any} di4={any}", .{ di1.read(), di2.read(), di3.read(), di4.read() });
        // var payload = [_]u8{'h'};
        // radio.send(0x02, &payload, false, false);
        // tx.write(.Reset);
        // rx.write(.Reset);

        // hal.delay(1000);
        // tx.write(.Set);
        // rx.write(.Set);
    }
}
