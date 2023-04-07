const c = @cImport({
    @cInclude("coneRGB-gatt.h");
});

// pub const DfuService = struct {
//     pub const start = c.ATT_SERVICE_FE59_START_HANDLE;
//     pub const end = c.ATT_SERVICE_FE59_END_HANDLE;
// };

// pub const DfuCharacteristic = enum(u16) {
//     /// 0x8EC90001-F315-4F60-9FB8-838830DAEA50
//     control_point = c.ATT_CHARACTERISTIC_8EC90001_F315_4F60_9FB8_838830DAEA50_01_VALUE_HANDLE,
//     /// 0x8EC90002-F315-4F60-9FB8-838830DAEA50
//     packet = c.ATT_CHARACTERISTIC_8EC90002_F315_4F60_9FB8_838830DAEA50_01_VALUE_HANDLE,
//     _,
// };

pub const SyncCharacteristic = enum(u16) {
    /// 16 bit network id
    network_id = c.ATT_CHARACTERISTIC_00006931_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE,
    /// Client or Server
    role = c.ATT_CHARACTERISTIC_00006932_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE,
    /// Status + RSSI
    status = c.ATT_CHARACTERISTIC_00006933_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE,
    /// 8 bit node id
    node_id = c.ATT_CHARACTERISTIC_00006934_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE,
    _,
};

/// Configuration of the coneRGB sync protocol
pub const SyncService = struct {
    pub const start = c.ATT_SERVICE_00006930_0000_1000_8000_00805F9B34FB_START_HANDLE;
    pub const end = c.ATT_SERVICE_00006930_0000_1000_8000_00805F9B34FB_END_HANDLE;
};

pub const LedStripService = struct {
    pub const channel1_start = c.ATT_SERVICE_00006910_0000_1000_8000_00805F9B34FB_START_HANDLE;
    pub const channel1_end = c.ATT_SERVICE_00006910_0000_1000_8000_00805F9B34FB_END_HANDLE;
    pub const channel2_start = c.ATT_SERVICE_00006920_0000_1000_8000_00805F9B34FB_START_HANDLE;
    pub const channel2_end = c.ATT_SERVICE_00006920_0000_1000_8000_00805F9B34FB_END_HANDLE;
};

pub const LedStripCharacteristic = struct {
    pub const Channel1 = enum(u16) { nzr = c.ATT_CHARACTERISTIC_00006911_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE, rgb = c.ATT_CHARACTERISTIC_00006912_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE, _ };
    pub const Channel2 = enum(u16) { nzr = c.ATT_CHARACTERISTIC_00006921_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE, rgb = c.ATT_CHARACTERISTIC_00006922_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE, _ };
};
pub const HandleTag = enum { channel1, channel2, sync };

const std = @import("std");
pub const Handle = union(HandleTag) {
    channel1: LedStripCharacteristic.Channel1,
    channel2: LedStripCharacteristic.Channel2,
    sync: SyncCharacteristic,
    pub fn inspect(handle: u16) void {
        std.log.info(
            \\handle: 0x{x}
            \\channel1.start: 0x{x}
            \\channel1.end: 0x{x}
            \\channel2.start: 0x{x}
            \\channel2.end: 0x{x}
            \\sync.start: 0x{x}
            \\sync.end: 0x{x}
            \\
        , .{
            handle,
            LedStripService.channel1_start,
            LedStripService.channel1_end,
            LedStripService.channel2_start,
            LedStripService.channel2_end,
            SyncService.start,
            SyncService.end,
        });
    }

    pub fn get(handle: u16) ?@This() {
        if (handle > LedStripService.channel1_start and handle <= LedStripService.channel1_end) switch (@intToEnum(LedStripCharacteristic.Channel1, handle)) {
            .nzr, .rgb => |t| return .{ .channel1 = t },
            else => return null,
        } else if (handle > LedStripService.channel2_start and handle <= LedStripService.channel2_end) switch (@intToEnum(LedStripCharacteristic.Channel2, handle)) {
            .nzr, .rgb => |t| return .{ .channel2 = t },
            else => return null,
        } else if (handle > SyncService.start and handle <= SyncService.end) switch (@intToEnum(SyncCharacteristic, handle)) {
            .network_id, .role, .status, .node_id => |t| return .{ .sync = t },
            else => return null,
        } else return null;
    }
};

pub const profile_data = &c.profile_data;
