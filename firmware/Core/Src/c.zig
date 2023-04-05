pub const c = @cImport({
    @cDefine("__PROGRAM_START", "");
    @cInclude("stdint.h");
    @cInclude("main.h");
    // @cInclude("stm32g4xx_hal_conf.h");
    // @cInclude("stm32g4xx_hal_dma.h");
    // @cInclude("stm32g4xx_hal_fdcan.h");
    // @cInclude("stm32g4xx_hal_gpio.h");
    // @cInclude("stm32g4xx_hal_spi_ex.h");
    // @cInclude("stm32g4xx_hal_spi.h");
    // @cInclude("stm32g4xx_hal_tim_ex.h");
    // @cInclude("stm32g4xx_hal_tim.h");
    // @cInclude("stm32g4xx_hal_uart_ex.h");
    // @cInclude("stm32g4xx_hal_uart.h");
    // @cInclude("stm32g4xx_hal_usart_ex.h");
    // @cInclude("stm32g4xx_hal_usart.h");
    @cInclude("stm32g4xx_hal.h");
});

pub usingnamespace c;
