const Color = @import("../color.zig").Color;
const OperationState = @import("../channel.zig").OperationState;
index: usize = 1,
color: Color = Color.off,
pub fn state_run(self: *@This(), pixel_buffer: []Color) OperationState {
    _ = pixel_buffer;
    _ = self;
    return .complete;
}
