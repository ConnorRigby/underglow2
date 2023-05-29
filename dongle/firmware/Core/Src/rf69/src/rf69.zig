const std = @import("std");
const hal = @import("../../stm32g4xx_hal.zig");
pub const Registers = @import("registers.zig");
pub const Mode = enum { Tx, Rx, Standby, Sleep };

pub const Packet = struct { target_id: u10, sender_id: u10, ack_requested: u1, ack_received: u1, payload: []u8 };

spi: *hal.spi,
reset_gpio: *hal.gpio,
nss_gpio: *hal.gpio,
tx_buffer: [32]u8,
rx_buffer: [32]u8,
packet_buffer: [66]u8,
packet: ?Packet = null,
tick: u32,
mode: Mode,
address: u10,
rssi: i16,

pub fn init(
    spi_handle: *hal.spi,
    reset_handle: *hal.gpio,
    nss_handle: *hal.gpio,
    address: u10,
) @This() {
    return .{
        //
        .address = address,
        .tick = hal.get_tick(),
        .spi = spi_handle,
        .reset_gpio = reset_handle,
        .nss_gpio = nss_handle,
        .rssi = undefined,
        .tx_buffer = undefined,
        .rx_buffer = undefined,
        .packet_buffer = undefined,
        .mode = undefined,
    };
}

pub fn reset(self: *@This()) void {
    std.mem.set(u8, &self.tx_buffer, 0);
    std.mem.set(u8, &self.rx_buffer, 0);
    std.mem.set(u8, &self.packet_buffer, 0);
    self.packet = null;

    self.reset_gpio.write(.Set);
    hal.delay(10);
    self.reset_gpio.write(.Reset);
    hal.delay(10);

    var tick = hal.get_tick();
    var reg_sync_value: u8 = 0;
    while (tick < 1000 and reg_sync_value != 0xaa) : (tick = hal.get_tick()) {
        self.write_register(.{ .RegSyncValue1 = @as(u8, 0xaa) });
        reg_sync_value = self.read_register(.RegSyncValue1).RegSyncValue1;
    }

    if (reg_sync_value != 0xaa) {
        std.log.err("sync={x}", .{reg_sync_value});
        @panic("sync");
    }

    const config = [_]Registers.Value{
        .{ .RegOpMode = .{ .listen_on = 0, .mode = .Standby, .sequencer_off = 0, .listen_abort = 0 } },
        .{ .RegDataModul = .{ .data_mode = .Packet, .modulation = .FskNoShapeing } },
        .{ .RegBitrateMsb = 0x2 },
        .{ .RegBitrateLsb = 0x40 },
        .{ .RegFdevMsb = 0x3 },
        .{ .RegFdevLsb = 0x33 },
        .{ .RegFrfMsb = 0xe4 },
        .{ .RegFrMid = 0xc0 },
        .{ .RegFrfLsb = 0x0 },
        .{ .RegRxBw = .{ .exp = 0x02, .mant = .Mant16, .dcc_freq = 0b010 } },
        // .{ .RegDioMapping1 = .{ .dio3 = 0, .dio2 = 0, .dio1 = 0, .dio0 = 1 } },
        // .{ .RegDioMapping2 = .{ .clk_out = 1, .dio5 = 0, .dio4 = 0 } },
        .{ .RegDioMapping1 = 0x40 },
        .{ .RegDioMapping2 = 0x07 },
        .{ .RegIrqFlags2 = .{ .low_bat = 0, .crc_ok = 0, .payload_ready = 0, .packet_sent = 0, .fifo_overrun = 1, .fifo_level = 0, .fifo_not_empty = 0, .fifo_full = 0 } },
        .{ .RegRssiThresh = 220 },
        // .{ .RegSyncConfig = .{ .on = 1, .fill_condition = 1, .size = 2, .tol = 0 } },
        .{ .RegSyncConfig = 0x88 },
        .{ .RegSyncValue1 = 0x2d },
        .{ .RegSyncValue2 = 0x64 },
        .{ .RegPacketConfig1 = 0x90 },
        .{ .RegPayloadLength = 66 },
        .{ .RegFifoThresh = .{ .fifo_threshold = 0x0f, .tx_start_condition = 1 } },
        // .{ .RegPacketConfig2 = .{ .aes_on = 0, .auto_rx_restart_on = 0, .restart_rx = 0, .inter_packet_rx_delay = 0b10 } },
        .{ .RegPacketConfig2 = 0x10 },
        .{ .RegTestDagc = 0x30 },
        // .{ .RegOcp = .{ .enabled = 0, .ocp_trim = 0b1010 } },
    };
    for (config) |c| self.write_register(c);
    self.write_register(.{ .RegPacketConfig2 = 0x10 });
    self.write_register(.{ .RegOcp = 0x1a });
    self.write_register(.{ .RegPaLevel = 0x9f });
    self.write_register(.{ .RegOcp = 0xf });
    self.write_register(.{ .RegTestPa1 = 0x5d });
    self.write_register(.{ .RegTestPa2 = 0x7c });
    self.write_register(.{ .RegPaLevel = 0x7f });

    self.set_mode(.Standby);
    self.write_register(.{ .RegTestPa1 = 0x55 });
    self.write_register(.{ .RegTestPa2 = 0x70 });
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
    self.write_register(.{ .RegOpMode = reg_op_mode });
    while (mode == .Sleep) blk: {
        if (self.read_register(.RegIrqFlags1).RegIrqFlags1.mode_ready == 1) break :blk;
    }
    self.mode = mode;
}

pub fn service_interrupt(self: *@This()) void {
    const irq_flags2 = self.read_register(.RegIrqFlags2).RegIrqFlags2;
    if (self.mode == .Rx and irq_flags2.payload_ready == 1) {
        std.mem.set(u8, &self.tx_buffer, 0);
        std.mem.set(u8, &self.rx_buffer, 0);
        std.mem.set(u8, &self.packet_buffer, 0);

        self.set_mode(.Standby);
        self.select();
        self.tx_buffer[0] = @enumToInt(Registers.Name.RegFifo) & 0x7f;
        self.spi.transcieve(self.tx_buffer[0..5], self.rx_buffer[0..5], 100) catch @panic("trx");
        var payload_length = if (self.rx_buffer[1] > 66) 66 else self.rx_buffer[1];
        var target_id = @as(u10, self.rx_buffer[2]);
        var sender_id = @as(u10, self.rx_buffer[3]);
        const ctl_byte = self.rx_buffer[4];
        target_id |= @truncate(u10, @as(u16, ctl_byte) & 0x0c << 6);
        sender_id |= @truncate(u10, @as(u16, ctl_byte) & 0x0c << 8);
        if ((target_id != self.address and target_id != 0) or payload_length < 3) {
            self.unselect();
            self.receive_begin();
            return;
        }
        payload_length -= 3;
        const ack_received = ctl_byte & 0x80;
        const ack_requested = ctl_byte & 40;
        self.spi.receive(self.packet_buffer[0..payload_length], 100) catch @panic("rx");
        self.packet_buffer[payload_length] = 0;
        self.unselect();
        self.set_mode(.Rx);
        std.log.info("rx ctrl_byte={x}", .{ctl_byte});
        self.packet = .{ .target_id = target_id, .sender_id = sender_id, .ack_requested = @truncate(u1, ack_requested), .ack_received = @truncate(u1, ack_received), .payload = self.packet_buffer[0..payload_length] };
    }
    self.rssi = self.read_rssi();
}

pub fn send(self: *@This(), address: u10, buffer: []u8, request_ack: bool, send_ack: bool) void {
    if (buffer.len > self.packet_buffer.len) @panic("packet too large");

    std.mem.set(u8, &self.tx_buffer, 0);
    std.mem.set(u8, &self.rx_buffer, 0);
    std.mem.set(u8, &self.packet_buffer, 0);

    self.set_mode(.Standby);
    while (self.read_register(.RegIrqFlags1).RegIrqFlags1.mode_ready == 0) {}
    std.log.info("tx modeready", .{});
    var ctlbyte: u8 = if (request_ack) 0x80 else if (send_ack) 0x40 else 0;
    if (address > 0xff) ctlbyte |= @truncate(u8, (address & 0x300) >> 6);
    if (self.address > 0xff) ctlbyte |= @truncate(u8, (self.address & 0x300) >> 8);
    self.tx_buffer[0] = @enumToInt(Registers.Name.RegFifo) | 0x80;
    self.tx_buffer[1] = @intCast(u8, buffer.len + 3);
    self.tx_buffer[2] = @intCast(u8, address);
    self.tx_buffer[3] = @intCast(u8, self.address);
    self.tx_buffer[4] = ctlbyte;
    std.log.info("len={x} to={x} from={x} ctl={x}", .{ self.tx_buffer[1], self.tx_buffer[2], self.tx_buffer[3], self.tx_buffer[4] });
    std.log.info("send packet: {x} {x} payload: {x}", .{ ctlbyte, std.fmt.fmtSliceHexLower(self.tx_buffer[0..5]), std.fmt.fmtSliceHexLower(buffer) });
    self.select();
    self.spi.transmit(self.tx_buffer[0..5], 100) catch @panic("tx");
    self.spi.transmit(buffer[0..], 100) catch @panic("tx");
    self.unselect();
    self.set_mode(.Tx);
    while (self.read_register(.RegIrqFlags2).RegIrqFlags2.packet_sent == 0) {}
    self.set_mode(.Standby);
}

pub fn receive_done(self: *@This()) ?Packet {
    if (self.packet) |packet| {
        self.set_mode(.Standby);
        self.packet = null;
        return packet;
    } else if (self.mode == .Rx) {
        return null;
    } else {
        self.receive_begin();
        return null;
    }
    unreachable;
}

pub fn read_register(self: *@This(), comptime name: Registers.Name) Registers.Value {
    const size = Registers.get_size(name);
    std.mem.set(u8, &self.tx_buffer, 0);
    std.mem.set(u8, &self.rx_buffer, 0);
    self.tx_buffer[0] = @enumToInt(name) & 0x7F;
    self.transcieve(self.tx_buffer[0 .. size + 1], self.rx_buffer[0 .. size + 1]);
    return Registers.handle_read(name, self.rx_buffer[1 .. size + 1]);
}

pub fn write_register(self: *@This(), value: Registers.Value) void {
    const size = value.get_size();
    std.mem.set(u8, &self.tx_buffer, 0);
    std.mem.set(u8, &self.rx_buffer, 0);
    Registers.handle_write(value, self.tx_buffer[0 .. size + 1]);
    self.transcieve(self.tx_buffer[0 .. size + 1], self.rx_buffer[0 .. size + 1]);
}

fn receive_begin(self: *@This()) void {
    self.packet = null;
    self.rssi = 0;
    if (self.read_register(.RegIrqFlags2).RegIrqFlags2.payload_ready == 1) {
        var packet_config_2 = self.read_register(.RegPacketConfig2).RegPacketConfig2;
        self.write_register(.{ .RegPacketConfig2 = (packet_config_2 & 0xFB) | 0x04 });
    }
    self.write_register(.{ .RegDioMapping1 = 0x40 });
    self.set_mode(.Rx);
}

fn read_rssi(self: *@This()) i16 {
    // self.write_register(.{ .RegRssiConfig = .{ .start = 1, .done = 0 } });
    // while (self.read_register(.RegRssiConfig).RegRssiConfig.done == 0) {}
    // self.write_register(.{ .RegRssiConfig = 0x01 });
    // while (self.read_register(.RegRssiConfig).RegRssiConfig & 0x02 == 0) {}

    var rssi: i16 = -@as(i16, self.read_register(.RegRssiValue).RegRssiValue);
    // var rssi: i16 = -rssi_;
    // std.log.info("rssi: {d}", .{rssi});
    rssi >>= 1;
    return rssi;
}

fn transcieve(self: *@This(), tx: []u8, rx: []u8) void {
    self.nss_gpio.write(.Reset);
    self.spi.transcieve(tx, rx, 10) catch @panic("transcieve");
    self.nss_gpio.write(.Set);
}

inline fn select(self: *@This()) void {
    self.nss_gpio.write(.Reset);
}
inline fn unselect(self: *@This()) void {
    self.nss_gpio.write(.Set);
}

test {
    std.testing.refAllDecls(Registers);
}
