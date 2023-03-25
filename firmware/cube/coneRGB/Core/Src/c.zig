pub const c = @cImport({
    @cInclude("main.h");
    @cInclude("stm32f4xx_hal.h");
    @cInclude("stm32f4xx_hal_gpio.h");
    @cInclude("stm32f4xx_hal_spi.h");
    @cInclude("stm32f4xx_hal_can.h");
});

pub usingnamespace c;
