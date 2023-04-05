const c = @import("c.zig");

pub const Gpio = struct { port: u16, pin: u16 };

pub const Rf69 = struct {
    nss: Gpio = .{ .port = c.RF69_NSS_GPIO_Port, .pin = c.RF69_NSS_Pin },
    nreset: Gpio = .{ .port = c.RF69_NRESET_GPIO_Port, .pin = c.RF69_NRESET_Pin },
    sck: Gpio = .{ .port = c.RF69_SCK_GPIO_Port, .pin = c.RF69_SCK_Pin },
    mosi: Gpio = .{ .port = c.RF69_MOSI_GPIO_Port, .pin = c.RF69_MOSI_Pin },
    miso: Gpio = .{ .port = c.RF69_MISO_GPIO_Port, .pin = c.RF69_MISO_Pin },
    irq: Gpio = .{ .port = c.RF69_IRQ_GPIO_Port, .pin = c.RF69_IRQ_Pin },
};

/// RF69 Packet Radio SPI bus
pub const rf69: Rf69 = .{};

pub const Hci = struct {
    rts: Gpio = .{ .port = c.HCI_RTS_GPIO_Port, .pin = c.HCI_RTS_Pin },
    cts: Gpio = .{ .port = c.HCI_CTS_GPIO_Port, .pin = c.HCI_CTS_Pin },
    rx: Gpio = .{ .port = c.HCI_RX_GPIO_Port, .pin = c.HCI_RX_Pin },
    tx: Gpio = .{ .port = c.HCI_TX_GPIO_Port, .pin = c.HCI_TX_Pin },
};

/// BLE HCI port
pub const hci: Hci = .{};

pub const Channel = struct { en: Gpio, nrz: Gpio, r: Gpio, g: Gpio, b: Gpio };

/// RGB + NRZ Channel 1
pub const channel0: Channel = .{
    .en = .{ .port = c.CH1_EN_GPIO_Port, .pin = c.CH1_EN_Pin },
    .nrz = .{ .port = c.CH1_NRZ_GPIO_Port, .pin = c.CH1_NRZ_Pin },
    .r = .{ .port = c.CH1_R_GPIO_Port, .pin = c.CH1_R_Pin },
    .g = .{ .port = c.CH1_G_GPIO_Port, .pin = c.CH1_G_Pin },
    .b = .{ .port = c.CH1_B_GPIO_Port, .pin = c.CH1_B_Pin },
};

/// RGB + NRZ Channel 2
pub const channel2: Channel = .{
    .en = .{ .port = c.CH2_EN_GPIO_Port, .pin = c.CH2_EN_Pin },
    .nrz = .{ .port = c.CH2_NRZ_GPIO_Port, .pin = c.CH2_NRZ_Pin },
    .r = .{ .port = c.CH2_R_GPIO_Port, .pin = c.CH2_R_Pin },
    .g = .{ .port = c.CH2_G_GPIO_Port, .pin = c.CH2_G_Pin },
    .b = .{ .port = c.CH2_B_GPIO_Port, .pin = c.CH2_B_Pin },
};

pub const StatusLeds = struct {
    tx: Gpio = .{ .port = c.STATUS_LED_GREEN_TX_Port, .pin = c.STATUS_LED_GREEN_TX_Pin },
    rx: Gpio = .{ .port = c.STATUS_LED_YELLOW_RX_Port, .pin = c.STATUS_LED_YELLOW_RX_Pin },
};
/// TX and RX LEDs
pub const status_leds: StatusLeds = .{};

/// User mappable digital input 1
pub const di1: Gpio = .{ .port = c.DI1_Port, .pin = c.DI1_Pin };

/// User mappable digital input 2
pub const di2: Gpio = .{ .port = c.DI2_Port, .pin = c.DI2_Pin };

/// User mappable digital input 3
pub const di3: Gpio = .{ .port = c.DI3_Port, .pin = c.DI3_Pin };

/// User mappable digital input 4
pub const di4: Gpio = .{ .port = c.DI4_Port, .pin = c.DI4_Pin };
