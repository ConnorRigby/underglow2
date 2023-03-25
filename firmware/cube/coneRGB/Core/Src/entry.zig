const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");

const hal = @import("stm32f4xx_hal.zig");
const rf69 = @import("lib/rf69/src/main.zig");

var log_buffer: [255]u8 = undefined;

pub const std_options = struct {
    // Set the log level to info
    pub const log_level = .info;
    // Define logFn to override the std implementation
    pub const logFn = log_to_uart2;
};

var huart2 = @extern(?*anyopaque, .{ .name = "huart2" });
extern fn HAL_UART_Transmit(?*anyopaque, [*c]const u8, u16, u32) c_int;

var hspi1 = @extern(?*c.SPI_HandleTypeDef, .{ .name = "hspi1" });
var hspi2 = @extern(?*c.SPI_HandleTypeDef, .{ .name = "hspi2" });

pub fn log_to_uart2(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    _ = scope;
    var printed = std.fmt.bufPrint(&log_buffer, format ++ "\r\n", args) catch return;
    _ = nosuspend HAL_UART_Transmit(huart2, printed.ptr, @intCast(u16, printed.len), 1000);
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    @setCold(true);
    _ = error_return_trace;
    _ = return_address;
    switch (builtin.os.tag) {
        .freestanding => {
            var printed = std.fmt.bufPrint(&log_buffer, "PANIC: {s}\r\n", .{msg}) catch while (true) @breakpoint();
            _ = HAL_UART_Transmit(huart2, printed.ptr, @intCast(u16, printed.len), 1000);
            while (true) @breakpoint();
        },
        else => @compileError("Only supported on freestanding"),
    }
}

export fn entry() callconv(.C) void {
    std.log.info("hello, from {s}", .{"logger"});

    var pd15 = hal.gpio.init(.{ .D = .{ .pin = .@"15", .mode = .OutputPushPull, .pull = .None, .speed = .Low } });
    defer pd15.deinit();

    var pb5 = hal.gpio.init(.{ .B = .{ .pin = .@"5", .mode = .OutputPushPull, .pull = .None, .speed = .Low } });
    defer pb5.deinit();

    var pa15 = hal.gpio.init(.{ .A = .{ .pin = .@"15", .mode = .OutputPushPull, .pull = .None, .speed = .Low } });
    defer pa15.deinit();

    // toggle RF69 reset pin
    var spi1 = hal.spi.init(hspi1);

    var tx = [_:0]u8{ 0x10, 0xff };
    var rx = [_:0]u8{ 0x10, 0x10 };

    // spi2.transcieve(&tx, &rx, 1000) catch @panic("SPI TRX failed");
    // hal.delay(1000);
    // @panic("uwu Something mega cringe happened :( ");
    pb5.write(.Set);
    hal.delay(11);
    pb5.write(.Reset);
    // hal.delay(10);

    while (true) {
        // pd15.toggle();
        // pb5.toggle();

        pa15.write(.Reset);
        spi1.transcieve(&tx, &rx, 10) catch @panic("trx");
        // spi1.transmit(&tx, 10) catch @panic("tx");
        // pa15.write(.Set);
        // // hal.delay(1);

        // pa15.write(.Reset);
        // spi1.receive(&rx, 10) catch @panic("rx");
        pa15.write(.Set);

        // std.log.info("tx={{0x{x}, 0x{x}}} rx={{0x{x},0x{x}}}", .{ tx[0], tx[1], rx[0], rx[1] });
        std.log.info("tx={{0x{x}, 0x{x}}} rx={{0x{x}, 0x{x}}}", .{ tx[0], tx[1], rx[0], rx[1] });
        // while (true) {}
        // tx[0] += 1;
        hal.delay(1000);
    }
}
