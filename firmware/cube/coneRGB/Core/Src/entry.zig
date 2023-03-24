const std = @import("std");
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

const c = @cImport({
    @cInclude("main.h");
    @cInclude("stm32f4xx_hal.h");
    @cInclude("stm32f4xx_hal_gpio.h");
});

var hspi1 = @extern(?*c.SPI_HandleTypeDef, .{ .name = "hspi1" });

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

export fn entry() callconv(.C) void {
    std.log.info("hello, from {s}", .{"logger"});
    var GPIO_InitStruct: c.GPIO_InitTypeDef = undefined;

    GPIO_InitStruct.Pin = c.GPIO_PIN_15;
    GPIO_InitStruct.Mode = c.GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = c.GPIO_NOPULL;
    GPIO_InitStruct.Speed = c.GPIO_SPEED_FREQ_LOW;
    c.HAL_GPIO_Init(c.GPIOD, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = c.GPIO_PIN_5;
    GPIO_InitStruct.Mode = c.GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = c.GPIO_NOPULL;
    GPIO_InitStruct.Speed = c.GPIO_SPEED_FREQ_LOW;
    c.HAL_GPIO_Init(c.GPIOB, &GPIO_InitStruct);

    // toggle RF69 reset pin
    c.HAL_GPIO_WritePin(c.GPIOB, c.GPIO_PIN_5, c.GPIO_PIN_RESET);
    c.HAL_GPIO_WritePin(c.GPIOB, c.GPIO_PIN_5, c.GPIO_PIN_SET);
    c.HAL_Delay(10);
    c.HAL_GPIO_WritePin(c.GPIOB, c.GPIO_PIN_5, c.GPIO_PIN_RESET);
    var spi_tx_buffer: [128:0]u8 = undefined;
    var spi_rx_buffer: [255:0]u8 = undefined;
    spi_tx_buffer[0] = 0x10;
    _ = c.HAL_SPI_TransmitReceive(hspi1, &spi_tx_buffer, &spi_rx_buffer, spi_tx_buffer[0..1].len, 1000);
    std.log.info("tx: {x} rx: {x}", .{ spi_tx_buffer[0], spi_rx_buffer[0] });
    var s: bool = false;
    while (true) {
        c.HAL_Delay(250);
        if (s) {
            c.HAL_GPIO_WritePin(c.GPIOD, c.GPIO_PIN_15, c.GPIO_PIN_SET);
            s = false;
        } else {
            c.HAL_GPIO_WritePin(c.GPIOD, c.GPIO_PIN_15, c.GPIO_PIN_RESET);
            s = true;
        }
    }
}
