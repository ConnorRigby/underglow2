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

    // var nss = hal.gpio.init(.{ .A = .{ .pin = .@"4", .mode = .OutputOpenDrain, .pull = .None, .speed = .Low } });
    var nss = hal.gpio.initDefault(.A, .@"4");
    nss.write(.Set);

    // var reset = hal.gpio.init(.{ .B = .{ .pin = .@"0", .mode = .OutputPushPull, .pull = .Down, .speed = .Low } });
    var reset = hal.gpio.initDefault(.B, .@"0");
    nss.write(.Set);

    // while (true) {
    //     std.log.info("set", .{});
    //     nss.write(.Set);
    //     reset.write(.Set);
    //     tx.write(.Set);
    //     rx.write(.Set);

    //     hal.delay(1000);
    //     std.log.info("reset", .{});
    //     reset.write(.Reset);
    //     tx.write(.Reset);
    //     rx.write(.Reset);
    //     hal.delay(1000);
    // }
    var radio = rf69.Rf69.init(&spi1, &reset, &nss);
    radio.reset();
    // var tx_data: [1]u8 = .{0};
    // var rx_data: [1]u8 = .{0};
    // for (1..0x4f) |i| {
    //     nss.write(.Reset);
    //     tx_data[0] = @intCast(u8, i) & 0x7f;
    //     spi1.transmit(&tx_data, 10) catch @panic("tx");
    //     spi1.receive(&rx_data, 10) catch @panic("rx");
    //     nss.write(.Set);
    //     std.log.info("address={x} value={x}", .{ tx_data[0], rx_data[0] });
    // }
    var opmode = radio.read_register(.RegOpMode);
    std.log.info("RegOpMode: {any}", .{opmode});

    radio.write_register(.{ .RegSyncValue = @as(u64, 0xaa) });
    var sync_value = radio.read_register(.RegSyncValue);
    std.log.info("sync_value: {any}", .{sync_value});

    // while (true) {
    //     radio.write_register(.{ .RegSyncValue = @as(u64, 0xaa) });
    //     var sync_value = radio.read_register(.RegSyncValue);
    //     std.log.info("sync_value: {any}", .{sync_value});
    //     hal.delay(1000);
    // }

    while (true) {
        hal.delay(1000);
        tx.write(.Reset);
        rx.write(.Reset);

        hal.delay(1000);
        tx.write(.Set);
        rx.write(.Set);
    }
}

// nss.write(.Set);
// reset.write(.Reset);
// hal.delay(10);
// reset.write(.Set);

// std.log.info("radio transaction start", .{});
// nss.write(.Set);
// var spi1 = hal.spi.init(handles.hspi1);
// var tx_buffer: [2]u8 = .{ 0, 0 };
// var rx_buffer: [2]u8 = .{ 0, 0 };
// for (1..@as(u8, 0x4f)) |i| {
//     nss.write(.Reset);
//     tx_buffer[0] = @intCast(u8, i) & 0x7f;
//     spi1.transcieve(&tx_buffer, &rx_buffer, 1000) catch {
//         @panic("spi transfer fail");
//     };
//     std.log.info("tx[0]={x} tx[1]={x} rx[0]={x} rx[1]={x}", .{ tx_buffer[0], tx_buffer[1], rx_buffer[0], rx_buffer[1] });
// }
// nss.write(.Set);
