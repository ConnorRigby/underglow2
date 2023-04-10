const Color = @import("../color.zig").Color;
const OperationState = @import("../channel.zig").OperationState;
index: usize = 0,
color: Color = Color.off,

pub fn state_run(self: *@This(), pixel_buffer: []Color) OperationState {
    pixel_buffer[self.index] = self.color;
    if (self.index + 1 == pixel_buffer.len) {
        self.index = 0;
        return .complete;
    } else {
        self.index += 1;
        return .work;
    }
}
