const c = @import("../c.zig");

pub const Status = enum(u8) {
    /// No error
    Ok = c.HAL_OK,
    /// Unknown error
    Error = c.HAL_ERROR,
    /// Busy
    Busy = c.HAL_BUSY,
    /// Timeout
    Timeout = c.HAL_TIMEOUT,
};

pub const Error = error{ Hal, Busy, Timeout };

pub const Lock = enum(u8) {
    Unlocked = c.HAL_UNLOCKED,
    Locked = c.HAL_LOCKED,
};
