const std = @import("std");
const testing = std.testing;
pub const Rf69 = @import("rf69.zig");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test {
    testing.refAllDecls(Rf69);
}
