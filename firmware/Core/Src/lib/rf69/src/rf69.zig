const std = @import("std");
const hal = @import("../../../stm32g4xx_hal.zig");
pub const Registers = @import("registers.zig");

spi: *hal.spi,
reset: *hal.gpio,
nss: *hal.gpio,
tx_buffer: [2]u8,
rx_buffer: [2]u8,

pub fn init(
    spi_handle: *hal.spi,
    reset_handle: *hal.gpio,
    nss_handle: *hal.gpio,
) @This() {
    return .{ .spi = spi_handle, .reset = reset_handle, .nss = nss_handle, .tx_buffer = .{ 0, 0 }, .rx_buffer = .{ 0, 0 } };
}

pub fn reset(self: *@This()) void {
    self.nss.write(.Set);
    self.reset.write(.Reset);
    hal.delay(10);
    self.reset.write(.Set);
}

pub fn read_register(self: *@This(), comptime register: Registers.Name) Registers.Value {
    self.select();

    self.tx_buffer[0] = @enumToInt(register);
    self.tx_buffer[1] = 0;

    self.rx_buffer[0] = 0;
    self.rx_buffer[1] = 0;

    self.spi.transcieve(&self.tx_buffer, &self.rx_buffer, 100) catch @panic("xfer fail");
    self.unselect();

    const x = switch (register) {
        inline else => |tag| {
            const T = std.meta.fieldInfo(Registers.Value, tag).type;
            const value = @bitCast(T, self.rx_buffer[0]);
            @unionInit(Registers.Value, @tagName(tag), value);
        },
    };
    return x;
}

inline fn select(self: *@This()) void {
    self.nss.write(.Reset);
}
inline fn unselect(self: *@This()) void {
    self.nss.write(.Set);
}

test {
    std.testing.refAllDecls(Registers);
}
