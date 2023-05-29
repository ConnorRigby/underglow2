const c = @import("c.zig");
pub const huart1 = @extern(?*c.UART_HandleTypeDef, .{ .name = "huart1" });
pub const hspi1 = @extern(?*c.SPI_HandleTypeDef, .{ .name = "hspi1" });
pub const hspi2 = @extern(?*c.SPI_HandleTypeDef, .{ .name = "hspi2" });
