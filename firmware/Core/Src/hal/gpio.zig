const c = @import("../c.zig");
const status = @import("status.zig");

pub const Pin = enum(u16) {
    @"0" = c.GPIO_PIN_0,
    @"1" = c.GPIO_PIN_1,
    @"2" = c.GPIO_PIN_2,
    @"3" = c.GPIO_PIN_3,
    @"4" = c.GPIO_PIN_4,
    @"5" = c.GPIO_PIN_5,
    @"6" = c.GPIO_PIN_6,
    @"7" = c.GPIO_PIN_7,
    @"8" = c.GPIO_PIN_8,
    @"9" = c.GPIO_PIN_9,
    @"10" = c.GPIO_PIN_10,
    @"11" = c.GPIO_PIN_11,
    @"12" = c.GPIO_PIN_12,
    @"13" = c.GPIO_PIN_13,
    @"14" = c.GPIO_PIN_14,
    @"15" = c.GPIO_PIN_15,
};

pub const Port = enum {
    A,
    B,
    C,
    D,
    E,
    F,
    // H,
    // G,
};

pub const Mode = enum(u32) {
    Input = c.GPIO_MODE_INPUT,
    OutputPushPull = c.GPIO_MODE_OUTPUT_PP,
    OutputOpenDrain = c.GPIO_MODE_OUTPUT_OD,
    AlternateFunctionPushPull = c.GPIO_MODE_AF_PP,
    AlternateFunctionOpenDrain = c.GPIO_MODE_AF_OD,
    Analog = c.GPIO_MODE_ANALOG,
    ItRising = c.GPIO_MODE_IT_RISING,
    ItFalling = c.GPIO_MODE_IT_FALLING,
    ItRisingFalling = c.GPIO_MODE_IT_RISING_FALLING,
    EventRising = c.GPIO_MODE_EVT_RISING,
    EventFalling = c.GPIO_MODE_EVT_FALLING,
    EventRisingFalling = c.GPIO_MODE_EVT_RISING_FALLING,
};

pub const Speed = enum(u32) {
    /// 2mhz
    Low = c.GPIO_SPEED_FREQ_LOW,
    /// 12,5-50mhz
    Medium = c.GPIO_SPEED_FREQ_MEDIUM,
    /// 25-100mhz
    High = c.GPIO_SPEED_FREQ_HIGH,
    /// 50-200mhz
    VeryHigh = c.GPIO_SPEED_FREQ_VERY_HIGH,
};

pub const Pull = enum(u32) {
    /// none
    None = c.GPIO_NOPULL,
    /// pull-up
    Up = c.GPIO_PULLUP,
    /// pull-down
    Down = c.GPIO_PULLDOWN,
};

pub const State = enum(u32) {
    /// logical one
    Set = c.GPIO_PIN_SET,
    /// logical zero
    Reset = c.GPIO_PIN_RESET,
};

pub const InitInner = struct {
    pin: Pin,
    mode: Mode,
    pull: Pull,
    speed: Speed,
};

pub const Init = union(Port) {
    A: InitInner,
    B: InitInner,
    C: InitInner,
    D: InitInner,
    E: InitInner,
    F: InitInner,
    // G: InitInner,
    // H: InitInner,
};

pin: Pin,
port: *c.GPIO_TypeDef,

pub fn init(gpio_init: Init) @This() {
    const port = switch (gpio_init) {
        .A => c.GPIOA,
        .B => c.GPIOB,
        .C => c.GPIOC,
        .D => c.GPIOD,
        .E => c.GPIOE,
        .F => c.GPIOF,
        // .G => c.GPIOG,
        // .H => c.GPIOH,
    };
    switch (gpio_init) {
        inline else => |inner| {
            var GPIO_InitStruct: c.GPIO_InitTypeDef = undefined;
            GPIO_InitStruct.Pin = @enumToInt(inner.pin);
            GPIO_InitStruct.Mode = @enumToInt(inner.mode);
            GPIO_InitStruct.Pull = @enumToInt(inner.pull);
            GPIO_InitStruct.Speed = @enumToInt(inner.speed);
            c.HAL_GPIO_Init(port, &GPIO_InitStruct);
            return .{ .port = port, .pin = inner.pin };
        },
    }
}

pub inline fn deinit(self: *const @This()) void {
    c.HAL_GPIO_DeInit(self.port, @enumToInt(self.pin));
}

pub inline fn write(self: *const @This(), state: State) void {
    c.HAL_GPIO_WritePin(self.port, @enumToInt(self.pin), @enumToInt(state));
}

pub inline fn read(self: *const @This()) State {
    var state = c.HAL_GPIO_ReadPin(self.port, @enumToInt(self.pin));
    return @intToEnum(State, state);
}

pub inline fn toggle(self: *const @This()) void {
    c.HAL_GPIO_TogglePin(self.port, @enumToInt(self.pin));
}

pub inline fn lock(self: *const @This()) status.Error!void {
    const s = c.HAL_GPIO_LockPin(self.port, self.port);
    return switch (@intToEnum(status.Status, s)) {
        .Ok => void,
        .Error => status.Error.Hal,
        .Busy => status.Error.Busy,
        .Timeout => status.Error.Timeout,
    };
}
