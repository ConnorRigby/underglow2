const Color = @import("../color.zig").Color;
const OperationState = @import("../channel.zig").OperationState;
index: usize = 1,

pub fn state_run(self: *@This(), pixel_buffer: []Color) OperationState {
    if (self.index == 0) {
        @panic("invalid index");
    } else if (self.index + 1 >= pixel_buffer.len) {
        self.index = 1;
        return .complete;
    } else {
        var snake = pixel_buffer[self.index - 1 .. self.index + 1];
        for (snake) |*c| c.*.raw = 0xff00ffff;
        for (0..self.index - 1) |i| {
            pixel_buffer[i].raw = 0;
        }
        for (self.index + 1..pixel_buffer.len) |i| {
            pixel_buffer[i].raw = 0;
        }
    }

    self.index += 1;
    return .work;
}
