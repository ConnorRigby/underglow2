const std = @import("std");
const hal = @import("../../../stm32g4xx_hal.zig");
pub const Registers = @import("registers.zig");

spi: *hal.spi,
reset_gpio: *hal.gpio,
nss_gpio: *hal.gpio,
tx_buffer: [32]u8,
rx_buffer: [32]u8,

pub fn init(
    spi_handle: *hal.spi,
    reset_handle: *hal.gpio,
    nss_handle: *hal.gpio,
) @This() {
    return .{ .spi = spi_handle, .reset_gpio = reset_handle, .nss_gpio = nss_handle, .tx_buffer = undefined, .rx_buffer = undefined };
}

pub fn reset(self: *@This()) void {
    std.log.info("reset", .{});
    self.nss_gpio.write(.Set);

    self.reset_gpio.write(.Set);
    hal.delay(10);
    self.reset_gpio.write(.Reset);
    hal.delay(10);
}

pub fn read_register(self: *@This(), comptime name: Registers.Name) Registers.Value {
    std.mem.set(u8, &self.tx_buffer, 0);
    std.mem.set(u8, &self.rx_buffer, 0);

    self.tx_buffer[0] = @enumToInt(name) & 0x7F;
    self.tx_buffer[1] = 0;

    self.rx_buffer[0] = 0;
    self.rx_buffer[1] = 0;

    self.select();
    self.spi.transmit(self.tx_buffer[0..1], 10) catch @panic("tx");
    self.spi.receive(self.rx_buffer[0..1], 10) catch @panic("tx");
    // self.spi.transcieve(self.tx_buffer[0..1], self.rx_buffer[0..1], 1) catch @panic("trx");
    self.unselect();
    // std.log.info("tx={x} rx={x}", .{ std.fmt.fmtSliceHexLower(&self.tx_buffer), std.fmt.fmtSliceHexLower(&self.rx_buffer) });

    return Registers.handle_read(name, &self.rx_buffer);
}

pub fn write_register(self: *@This(), value: Registers.Value) void {
    std.mem.set(u8, &self.tx_buffer, 0);
    std.mem.set(u8, &self.rx_buffer, 0);

    self.tx_buffer[0] = @enumToInt(@as(Registers.Name, value)) | 0x80;
    std.log.info("tx={x} rx={x}", .{ std.fmt.fmtSliceHexLower(&self.tx_buffer), std.fmt.fmtSliceHexLower(&self.rx_buffer) });

    var fbs = std.io.fixedBufferStream(self.tx_buffer[1..]);
    const writer = fbs.writer();
    const size: usize = switch (value) {
        inline else => |tag| blk: {
            switch (@typeInfo(@TypeOf(tag))) {
                .Int => writer.writeIntLittle(@TypeOf(tag), tag) catch @panic("writeIntLittle"),
                .Struct => writer.writeStruct(tag) catch @panic("writeStruct"),
                .Array => writer.writeAll(&tag) catch @panic("writeAll"),
                inline else => @compileError("invalid type" ++ @typeName(@TypeOf(tag))),
            }
            break :blk @sizeOf(@TypeOf(tag));
        },
    };
    std.log.info("[size={d} tx={x} rx={x}", .{ size, std.fmt.fmtSliceHexLower(self.tx_buffer[0 .. size + 1]), std.fmt.fmtSliceHexLower(self.rx_buffer[0 .. size + 1]) });
    self.select();
    self.spi.transcieve(self.tx_buffer[0 .. size + 1], self.rx_buffer[0 .. size + 1], 100) catch @panic("xfer fail");
    self.unselect();
    std.log.info("[size={d} tx={x} rx={x}", .{ size, std.fmt.fmtSliceHexLower(self.tx_buffer[0 .. size + 1]), std.fmt.fmtSliceHexLower(self.rx_buffer[0 .. size + 1]) });
}

inline fn select(self: *@This()) void {
    std.log.info("select", .{});
    self.nss_gpio.write(.Reset);
}
inline fn unselect(self: *@This()) void {
    self.nss_gpio.write(.Set);
    std.log.info("unselect", .{});
}

test {
    std.testing.refAllDecls(Registers);
}
