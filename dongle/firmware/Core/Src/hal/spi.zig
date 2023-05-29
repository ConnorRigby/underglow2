const c = @import("../c.zig");
const status = @import("status.zig");

pub const State = enum(u8) {
    reset = c.HAL_SPI_STATE_RESET,
    ready = c.HAL_SPI_STATE_READY,
    busy = c.HAL_SPI_STATE_BUSY,
    tx = c.HAL_SPI_STATE_BUSY_TX,
    rx = c.HAL_SPI_STATE_BUSY_RX,
    tx_rx = c.HAL_SPI_STATE_BUSY_TX_RX,
    @"error" = c.HAL_SPI_STATE_ERROR,
    abort = c.HAL_SPI_STATE_ABORT,
};

handle: ?*c.SPI_HandleTypeDef,

pub fn init(handle: ?*c.SPI_HandleTypeDef) @This() {
    return .{ .handle = handle };
}

pub fn deinit(self: *const @This()) void {
    _ = self;
}

pub fn transmit(self: *@This(), data: []u8, timeout: u32) status.Error!void {
    const s = c.HAL_SPI_Transmit(self.handle, data.ptr, @intCast(u16, data.len), timeout);
    switch (@intToEnum(status.Status, s)) {
        .Ok => return,
        .Error => return status.Error.Hal,
        .Busy => return status.Error.Busy,
        .Timeout => return status.Error.Timeout,
    }
}

pub fn receive(self: *@This(), data: []u8, timeout: u32) status.Error!void {
    const s = c.HAL_SPI_Receive(self.handle, data.ptr, @intCast(u16, data.len), timeout);
    switch (@intToEnum(status.Status, s)) {
        .Ok => return,
        .Error => return status.Error.Hal,
        .Busy => return status.Error.Busy,
        .Timeout => return status.Error.Timeout,
    }
}

pub fn transcieve(self: *@This(), tx_data: []u8, rx_data: []u8, timeout: u32) status.Error!void {
    const s = c.HAL_SPI_TransmitReceive(self.handle, tx_data.ptr, rx_data.ptr, @intCast(u16, tx_data.len), timeout);
    switch (@intToEnum(status.Status, s)) {
        .Ok => return,
        .Error => return status.Error.Hal,
        .Busy => return status.Error.Busy,
        .Timeout => return status.Error.Timeout,
    }
}
