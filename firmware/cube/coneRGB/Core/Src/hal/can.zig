const std = @import("std");
const c = @import("../c.zig");

const status = @import("status.zig");

pub const State = enum(u8) { Reset, Ready, Listening, SleepPending, SleepActive, Error };

pub const Init = struct {};

pub const Fileter = struct {};

pub const TxHeader = struct {};

pub const RxHeader = struct {};

pub const Handle = struct {};

pub const ErrorStatus = enum(u32) { None = c.HAL_CAN_ERROR_NONE, Ewg = c.HAL_CAN_ERROR_EWG, Epv = c.HAL_CAN_ERROR_EPV, Bof = c.HAL_CAN_ERROR_BOF, Stf = c.HAL_CAN_ERROR_STF, For = c.HAL_CAN_ERROR_FOR, Ack = c.HAL_CAN_ERROR_ACK, Br = c.HAL_CAN_ERROR_BR, Bd = c.HAL_CAN_ERROR_BD, Crc = c.HAL_CAN_ERROR_CRC, RxFov0 = c.HAL_CAN_ERROR_RX_FOV0, RxFov1 = c.HAL_CAN_ERROR_RX_FOV1, TxAlst0 = c.HAL_CAN_ERROR_TX_ALST0, TxTerr0 = c.HAL_CAN_ERROR_TX_TERR0, TxAlst1 = c.HAL_CAN_ERROR_TX_ALST1, TxTerr1 = c.HAL_CAN_ERROR_TX_TERR1, TxAlst2 = c.HAL_CAN_ERROR_TX_ALST2, TxTerr2 = c.HAL_CAN_ERROR_TX_TERR2, Timeout = c.HAL_CAN_ERROR_TIMEOUT, NotInitialized = c.HAL_CAN_ERROR_NOT_INITIALIZED, NotReady = c.HAL_CAN_ERROR_NOT_READY, NotStarted = c.HAL_CAN_ERROR_NOT_STARTED, Param = c.HAL_CAN_ERROR_PARAM };

pub const InitStatus = enum(u32) {
    Failed = c.CAN_INITSTATUS_FAILED,
    Success = c.CAN_INITSTATUS_SUCCESS,
};

pub const Mode = enum(u32) { Normal = c.CAN_MODE_NORMAL, Loopback = c.CAN_MODE_LOOPBACK, Silent = c.CAN_MODE_SILENT, SilentLoopback = C.CAN_MODE_SILENT_LOOPBACK };

handle: ?*c.CAN_HandleTypeDef,

pub fn init(handle: ?*c.CAN_HandleTypeDef) @This() {
    return .{ .handle = handle };
}

pub fn start(self: *@This()) status.Error!void {
    const s = c.HAL_CAN_Start(self.handle);
    switch (@intToEnum(s.Status, s)) {
        .Ok => return,
        .Error => return status.Error.Hal,
        .Busy => return status.Error.Busy,
        .Timeout => return status.Error.Timeout,
    }
}

pub fn stop(self: *@This()) status.Error!void {
    const s = c.HAL_CAN_Stop(self.handle);
    switch (@intToEnum(s.Status, s)) {
        .Ok => return,
        .Error => return status.Error.Hal,
        .Busy => return status.Error.Busy,
        .Timeout => return status.Error.Timeout,
    }
}
