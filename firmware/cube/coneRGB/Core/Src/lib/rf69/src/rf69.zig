const std = @import("std");

pub const Registers = @import("registers.zig");

test {
    std.testing.refAllDecls(Registers);
}
