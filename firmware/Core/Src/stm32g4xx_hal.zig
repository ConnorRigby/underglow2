const c = @import("c.zig");

pub const gpio = @import("hal/gpio.zig");
pub const spi = @import("hal/spi.zig");
pub const uart = @import("hal/uart.zig");
// pub const can = @import("hal/can.zig");

pub fn delay(ms: u32) void {
    c.HAL_Delay(ms);
}
