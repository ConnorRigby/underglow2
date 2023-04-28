const std = @import("std");
const hal = @import("../../../stm32g4xx_hal.zig");
pub const Registers = @import("registers.zig");
pub const Mode = enum { Tx, Rx, Standby, Sleep };

spi: *hal.spi,
reset_gpio: *hal.gpio,
nss_gpio: *hal.gpio,
tx_buffer: [32]u8,
rx_buffer: [32]u8,
tick: u32,
mode: Mode,

pub fn init(
    spi_handle: *hal.spi,
    reset_handle: *hal.gpio,
    nss_handle: *hal.gpio,
) @This() {
    return .{
        //
        .tick = hal.get_tick(),
        .spi = spi_handle,
        .reset_gpio = reset_handle,
        .nss_gpio = nss_handle,
        .tx_buffer = undefined,
        .rx_buffer = undefined,
        .mode = undefined,
    };
}

pub fn reset(self: *@This()) void {
    self.reset_gpio.write(.Set);
    hal.delay(10);
    self.reset_gpio.write(.Reset);
    hal.delay(10);

    var tick = hal.get_tick();
    var reg_sync_value: u32 = 0;
    while (tick < 100) : (tick = hal.get_tick()) {
        self.write_register(.{ .RegSyncValue = @as(u64, 0xaa) });
        reg_sync_value = self.read_register(.RegSyncValue).RegSyncValue;
    }
    if (reg_sync_value != 0xaa) @panic("sync");

    const config = [_]Registers.Value{
        .{ .RegOpMode = .{ .listen_on = 0, .mode = .Standby, .sequencer_off = 0, .listen_abort = 0 } },
        .{ .RegDataModul = .{ .data_mode = .Packet, .modulation = .FskNoShapeing } },
        // .{.RegBitrate = 0x1a0b},
        .{ .RegRxBw = .{ .exp = 0x02, .mant = .Mant16, .dcc_freq = 0b010 } },
        .{ .RegDioMapping1 = .{ .dio3 = 0, .dio2 = 0, .dio1 = 0, .dio0 = 1 } },
        .{ .RegDioMapping2 = .{ .clk_out = 1, .dio5 = 0, .dio4 = 0 } },
        .{ .RegIrqFlags2 = .{ .low_bat = 0, .crc_ok = 0, .payload_ready = 0, .packet_sent = 0, .fifo_overrun = 1, .fifo_level = 0, .fifo_not_empty = 0, .fifo_full = 0 } },
        .{ .RegRssiThresh = 220 },
        .{ .RegSyncConfig = .{ .on = 1, .fill_condition = 0, .size = 0x2, .tol = 0 } },
        .{ .RegSyncValue = 0x2d6400 },
        .{ .RegPayloadLength = 66 },
        .{ .RegFifoThresh = .{ .fifo_threshold = 0x0f, .tx_start_condition = 1 } },
        .{ .RegPacketConfig2 = .{ .aes_on = 0, .auto_rx_restart_on = 0, .restart_rx = 0, .inter_packet_rx_delay = 0b10 } },
        .{ .RegTestDagc = 0x30 },
        .{ .RegOcp = .{ .enabled = 0, .ocp_trim = 0b1010 } },
    };
    for (config) |c| self.write_register(c);
}

pub fn set_mode(self: *@This(), mode: Mode) void {
    if (self.mode == mode) return;
    var reg_op_mode = self.read_register(.RegOpMode).RegOpMode;
    switch (mode) {
        .Tx => reg_op_mode.mode = .Transmitter,
        .Rx => reg_op_mode.mode = .Receiver,
        .Standby => reg_op_mode.mode = .Standby,
        .Sleep => reg_op_mode.mode = .Sleep,
    }
    while (mode == .Sleep) blk: {
        if (self.read_register(.RegIrqFlags1).RegIrqFlags1.mode_ready == 1) break :blk;
    }
    self.mode = mode;
}

pub fn read_register(self: *@This(), comptime name: Registers.Name) Registers.Value {
    const size = name.get_size();
    std.mem.set(u8, &self.tx_buffer, 0);
    std.mem.set(u8, &self.rx_buffer, 0);
    self.tx_buffer[0] = @enumToInt(name) & 0x7F;
    self.transcieve(self.tx_buffer[0 .. size + 1], self.rx_buffer[0 .. size + 1]);
    return Registers.handle_read(name, self.rx_buffer[0..size]);
}

pub fn write_register(self: *@This(), value: Registers.Value) void {
    const size = value.get_size();
    std.mem.set(u8, &self.tx_buffer, 0);
    std.mem.set(u8, &self.rx_buffer, 0);
    Registers.handle_write(value, self.tx_buffer[0 .. size + 1]);
    self.transcieve(self.tx_buffer[0 .. size + 1], self.rx_buffer[0 .. size + 1]);
}

fn transcieve(self: *@This(), tx: []u8, rx: []u8) void {
    self.nss_gpio.write(.Reset);
    self.spi.transcieve(tx, rx, 10) catch @panic("transcieve");
    self.nss_gpio.write(.Set);
}

// inline fn select(self: *@This()) void {
//     self.nss_gpio.write(.Reset);
// }
// inline fn unselect(self: *@This()) void {
//     self.nss_gpio.write(.Set);
// }

test {
    std.testing.refAllDecls(Registers);
}
