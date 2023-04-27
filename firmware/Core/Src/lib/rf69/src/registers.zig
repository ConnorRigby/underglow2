const std = @import("std");
pub const Name = enum(u8) {
    // register definition names
    RegFifo = 0x00,
    RegOpMode = 0x01,
    RegDataModul = 0x02,
    RegBitrate = 0x03,
    // RegBitrateMsb = 0x03,
    // RegBitrateLsb = 0x04,
    RegFdev = 0x05,
    // RegFdevMsb = 0x05,
    // RegFdevLsb = 0x06,
    RegFrf = 0x07,
    // RegFrfMsb = 0x07,
    // RegFrMid = 0x08,
    // RegFrfLsb = 0x09,
    RegOsc1 = 0x0A,
    RegAfcCtl = 0x0B,
    RegLowBat = 0x0C,
    RegListen1 = 0x0D,
    RegListen2 = 0x0E,
    RegListen3 = 0x0F,
    RegVersion = 0x10,
    RegPaLevel = 0x11,
    RegPaRamp = 0x12,
    RegOcp = 0x13,
    RegLna = 0x18,
    RegRxBw = 0x19,
    RegAfcBw = 0x1A,
    RegOokPeak = 0x1B,
    RegOokAvg = 0x1C,
    RegOokFix = 0x1D,
    RegAfcFei = 0x1E,
    RegAfc = 0x1F,
    // RegAfcMsb = 0x1F,
    // RegAfcLsb = 0x20,
    RegFei = 0x21,
    // RegFeiMsb = 0x21,
    // RegFeiLsb = 0x22,
    RegRssiConfig = 0x23,
    RegRssiValue = 0x24,
    RegDioMapping1 = 0x25,
    RegDioMapping2 = 0x26,
    RegIrqFlags1 = 0x27,
    RegIrqFlags2 = 0x28,
    RegRssiThresh = 0x29,
    RegRxTimeout1 = 0x2A,
    RegRxTimeout2 = 0x2B,
    RegPreamble = 0x2C,
    // RegPreambleMsb = 0x2C,
    // RegPreambleLsb = 0x2D,
    RegSyncConfig = 0x2E,
    RegSyncValue = 0x2F,
    // RegSyncValue1 = 0x2F,
    // RegSyncValue2 = 0x30,
    // RegSyncValue3 = 0x31,
    // RegSyncValue4 = 0x32,
    // RegSyncValue5 = 0x33,
    // RegSyncValue6 = 0x34,
    // RegSyncValue7 = 0x35,
    // RegSyncValue8 = 0x36,
    RegPacketConfig1 = 0x37,
    RegPayloadLength = 0x38,
    RegNodeAdrs = 0x39,
    RegBroadcastAdrs = 0x3A,
    RegAutoModes = 0x3B,
    RegFifoThresh = 0x3C,
    RegPacketConfig2 = 0x3D,
    RegAesKey = 0x3E,
    // RegAesKey1 = 0x3E,
    // RegAesKey2 = 0x3F,
    // RegAesKey3 = 0x40,
    // RegAesKey4 = 0x41,
    // RegAesKey5 = 0x42,
    // RegAesKey6 = 0x43,
    // RegAesKey7 = 0x44,
    // RegAesKey8 = 0x45,
    // RegAesKey9 = 0x46,
    // RegAesKey10 = 0x47,
    // RegAesKey11 = 0x48,
    // RegAesKey12 = 0x49,
    // RegAesKey13 = 0x4A,
    // RegAesKey14 = 0x4B,
    // RegAesKey15 = 0x4C,
    // RegAesKey16 = 0x4D,
    RegTemp1 = 0x4E,
    RegTemp2 = 0x4F,
    RegTestLna = 0x58,
    RegTestTcxo = 0x59,
    RegTestPIIBW = 0x5F,
    RegTestDagc = 0x6F,
    RegTestAfc = 0x71,
    // _,
};

pub const Value = union(Name) {
    /// 8 bit first in/first out data
    RegFifo: u8,
    /// operating mode
    RegOpMode: packed struct {
        // not used
        reserved: u2 = 0b00,
        /// operating mode
        mode: enum(u3) {
            //
            Sleep = 0b000,
            Standby = 0b001,
            FrequencySynthesizer = 0b010,
            Transmitter = 0b011,
            Receiver = 0b100,
            _,
        },
        listen_abort: u1,
        listen_on: u1,
        sequencer_off: u1,
    },
    RegDataModul: packed struct {
        // not used
        reserved: u1 = 0,
        modulation: enum(u7) {
            //
            FskNoShapeing = 0b00000,
            FskGaussianFilter10 = 0b01000,
            FskGaussianFilter05 = 0b10000,
            FskGaussianFilter03 = 0b11000,
            OokNoShaping = 0b00001,
            OokFCutoff10 = 0b010001,
            OokFCutoff20 = 0b100001,
            _,
        },
        data_mode: enum(u2) {
            /// packet mode
            Packet = 0b00,
            /// continuous mode 1
            ContinuousModeWithBitSyncronizer = 0b10,
            /// continuous mode 2
            ContinuousModeWithoutBitSyncronizer = 0b11,
        },
    },
    RegBitrate: u16,
    RegFdev: packed struct {
        /// not used
        reserved: u2 = 0,
        FrequencyDivision: u14,
    },
    RegFrf: u24,
    RegOsc1: packed struct {
        /// not used
        reserved: u5 = 0,
        calibration: packed struct {
            /// in progress or completed
            status: enum(u1) {
                Progress = 0b0,
                Over = 0b1,
            },
            // 1 is the only valid write
            start: enum(u1) { on = 0b01 },
        },
    },
    RegAfcCtl: packed struct {
        /// not used
        reserved: u5,
        routine: enum(u3) {
            /// improved alg
            Improved = 0b100,
            /// default alg
            Standard = 0b000,
            _,
        },
    },
    RegLowBat: packed struct {
        //
        trim: enum(u3) {
            //
            V1695 = 0b000,
            V1764 = 0b001,
            V1835 = 0b010,
            V1904 = 0b011,
            V1976 = 0b100,
            V2045 = 0b101,
            V2116 = 0b110,
            V2185 = 0b111,
        },
        enable: u1,
        monitor: u1,
        reserved: u3 = 0b000,
    },
    RegListen1: packed struct {
        //
        pub const Resol = enum(u2) { US64 = 0b01, MS41 = 0b10, MS262 = 0b11 };

        reserved: u1 = 0,
        end: enum(u2) {
            //
            Rx = 0b00,
            Dynamic = 0b01,
            PayloadReady = 0b10,
            _,
        },
        critera: enum(u1) {
            //
            RssiThreshold = 0b0,
            SyncAddress = 0b1,
        },
        resol_rx: Resol,
        resol_idle: Resol,
    },
    RegListen2: packed struct {
        //
        listen_coef_idle: u8 = 0xf5,
    },
    RegListen3: packed struct {
        //
        listen_coef_rx: u8 = 0x20,
    },
    RegVersion: u8,
    RegPaLevel: packed struct {
        //
        output_power: u5,
        pa2: u1,
        pa1: u1,
        oa0: u1,
    },
    RegPaRamp: packed struct {
        //
        ramp: enum(u4) {
            //
            MS34 = 0b000,
            MS2 = 0b0001,
            MS1 = 0b0010,
            US500 = 0b0011,
            US250 = 0b0100,
            US125 = 0b0101,
            US100 = 0b0110,
            US62 = 0b0111,
            US50 = 0b1000,
            US40 = 0b1001,
            US31 = 0b1010,
            US25 = 0b1011,
            US20 = 0b1100,
            US15 = 0b1101,
            US12 = 0b1110,
            US10 = 0b1111,
        },
        reserved: u4 = 0b0000,
    },
    RegOcp: packed struct {
        //
        ocp_trim: u4,
        enabled: u1,
        reserved: u3,
    },
    RegLna: packed struct {
        //
        gain_select: enum(u3) {
            //
            Agc = 0b000,
            Highest = 0b001,
            Highest6dB = 0b010,
            Highest12dB = 0b011,
            Highest24dB = 0b100,
            Highest36dB = 0b101,
            Highest48dB = 0b110,
            _,
        },
        gain_current: u3,
        reserved: u1 = 0,
        zin: enum(u1) {
            //
            Ohm50 = 0b0,
            Ohm200 = 0b1,
        },
    },
    RegRxBw: packed struct {
        //
        exp: u3,
        mant: enum(u2) {
            //
            Mant16 = 0b00,
            Mant20 = 0b01,
        },
        dcc_freq: u3,
    },
    RegAfcBw: packed struct {
        //
        exp: u3,
        mant: u2,
        freq: u3,
    },
    RegOokPeak: packed struct {
        dec: enum(u3) {
            //
            OncePerChip = 0b000,
            OnceEvery2Chips = 0b001,
            OnceEvery4Chips = 0b010,
            OnceEveryEightChips = 0b011,
            TwiceInEachChip = 0b100,
            EightTimesInEachChip = 0b110,
            FourTimessInEveryChip = 0b101,
            SixteenTimesInEachChip = 0b111,
        },
        step: enum(u3) {
            //
            dB05 = 0b000,
            dB10 = 0b001,
            dB15 = 0b010,
            dB20 = 0b011,
            dB30 = 0b100,
            dB40 = 0b101,
            dB50 = 0b110,
            dB60 = 0b111,
        },
        type: enum(u2) {
            //
            Fixed = 0b00,
            Peak = 0b01,
            Average = 0b10,
            _,
        },
    },
    RegOokAvg: packed struct {
        //
        reserved: u6 = 0,
        filt: u2,
    },
    RegOokFix: u8,
    RegAfcFei: packed struct {
        //
        afc_start: u1,
        afc_clear: u1,
        afc_auto: u1,
        afc_auto_clear: u1,
        afc_done: u1,
        fei_start: u1,
        fei_done: u1,
    },
    RegAfc: u16,
    RegFei: u16,
    RegRssiConfig: packed struct {
        //
        start: u1,
        done: u1,
        reserved: u6 = 0,
    },
    RegRssiValue: u8,
    RegDioMapping1: packed struct {
        //
        dio3: u2,
        dio2: u2,
        dio1: u2,
        dio0: u2,
    },
    RegDioMapping2: packed struct {
        //
        clk_out: u3,
        reserved: u1 = 0,
        dio5: u2,
        dio4: u2,
    },
    RegIrqFlags1: packed struct {
        //
        sync_address_match: u1,
        auto_mode: u1,
        timeout: u1,
        rssi: u1,
        pll_lock: u1,
        tx_ready: u1,
        rx_ready: u1,
        mode_ready: u1,
    },
    RegIrqFlags2: packed struct {
        //
        low_bat: u1,
        crc_ok: u1,
        payload_ready: u1,
        packet_sent: u1,
        fifo_overrun: u1,
        fifo_level: u1,
        fifo_not_empty: u1,
        fifo_full: u1,
    },
    RegRssiThresh: u8,
    RegRxTimeout1: packed struct {
        //
        timeout_rx_start: u8,
    },
    RegRxTimeout2: packed struct {
        //
        timeout_rssi_thresh: u8,
    },
    RegPreamble: u16,
    RegSyncConfig: packed struct {
        //
        tol: u3,
        size: u3,
        fill_condition: u1,
        on: u1,
    },
    RegSyncValue: u64,
    RegPacketConfig1: packed struct {
        //
        reserved: u1 = 0,
        address_filtering: u2,
        crc_auto_clear_off: u1,
        crc_on: u1,
        dc_free: u2,
        packet_format: u1,
    },
    RegPayloadLength: u8,
    RegNodeAdrs: u8,
    RegBroadcastAdrs: u8,
    RegAutoModes: packed struct {
        //
        intermediate_mode: u2,
        exit_condition: u3,
        enter_condition: u3,
    },
    RegFifoThresh: packed struct {
        //
        fifo_threshold: u7,
        tx_start_condition: u1,
    },
    RegPacketConfig2: packed struct {
        //
        aes_on: u1,
        auto_rx_restart_on: u1,
        restart_rx: u1,
        reserved: u1 = 0,
        inter_packet_rx_delay: u4,
    },
    RegAesKey: [16]u8,
    RegTemp1: packed struct {
        //
        reserved1: u2,
        meas_running: u1,
        meas_start: u1,
        reserved2: u4 = 0,
    },
    RegTemp2: u8,
    RegTestLna: u8,
    RegTestTcxo: u8,
    RegTestPIIBW: u8,
    RegTestDagc: u8,
    RegTestAfc: u8,
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
