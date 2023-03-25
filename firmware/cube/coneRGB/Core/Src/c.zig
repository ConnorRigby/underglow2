pub const c = @cImport({
    @cInclude("main.h");
    @cInclude("stm32f4xx_hal.h");
    @cInclude("stm32f4xx_hal_gpio.h");
});

pub usingnamespace c;
