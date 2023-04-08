const std = @import("std");
const c = @cImport({
    @cInclude("btstack_config.h");

    @cInclude("ble/le_device_db_tlv.h");
    @cInclude("bluetooth_company_id.h");
    @cInclude("btstack_debug.h");
    @cInclude("btstack_event.h");
    @cInclude("btstack_memory.h");
    @cInclude("btstack_run_loop.h");
    @cInclude("btstack_run_loop_posix.h");
    @cInclude("btstack_signal.h");
    @cInclude("btstack_stdin.h");
    @cInclude("btstack_tlv_posix.h");

    @cInclude("hci.h");
    @cInclude("hci_dump.h");
    @cInclude("hci_dump_posix_fs.h");
    @cInclude("hci_transport.h");
    @cInclude("hci_transport_usb.h");
    @cInclude("gap.h");
    @cInclude("att_server.h");
    @cInclude("bluetooth_data_types.h");
    @cInclude("ble/gatt-service/device_information_service_server.h");
    @cInclude("signal.h");
});

const ChannelState = @import("channel.zig");
const DigitalInputState = @import("digital_input.zig");
const sync = @import("sync.zig");

var channel1_state: ChannelState = .{};
var channel2_state: ChannelState = .{};
var sync_state: ?sync.Sync = null;
var digital_input1: DigitalInputState = .{};
var digital_input2: DigitalInputState = .{};
var digital_input3: DigitalInputState = .{};
var digital_input4: DigitalInputState = .{};

const gatt = @import("gatt.zig").Server(
    &channel1_state,
    &channel2_state,
    &sync_state,
    &digital_input1,
    &digital_input2,
    &digital_input3,
    &digital_input4,
);

var tlv_db_path: [:0]const u8 = "tlv.db";
var tlv_reset: bool = undefined;
var tlv_impl: [*c]const c.btstack_tlv_t = undefined;
var tlv_context: c.btstack_tlv_posix_t = undefined;
var local_addr: c.bd_addr_t = undefined;
var hci_event_callback_registration: c.btstack_packet_callback_registration_t = undefined;

pub fn state_packet_handler(packet_type: u8, channel: u16, packet: [*c]u8, size: u16) callconv(.C) void {
    _ = channel;
    _ = size;
    if (packet_type != c.HCI_EVENT_PACKET) return;
    switch (c.hci_event_packet_get_type(packet)) {
        c.BTSTACK_EVENT_STATE => switch (c.btstack_event_state_get_state(packet)) {
            c.HCI_STATE_WORKING => {
                c.gap_local_bd_addr(&local_addr);
                tlv_impl = c.btstack_tlv_posix_init_instance(&tlv_context, tlv_db_path);
                c.btstack_tlv_set_instance(tlv_impl, &tlv_context);
                c.le_device_db_tlv_configure(tlv_impl, &tlv_context);

                std.debug.print("HCI_STATE_WORKING\n", .{});
            },
            c.HCI_STATE_OFF => {
                std.debug.print("HCI_STATE_OFF\n", .{});
                std.os.exit(0);
            },
            else => {},
        },
        else => {},
    }
}

pub fn trigger_shutdown() callconv(.C) void {
    _ = c.hci_power_control(c.HCI_POWER_OFF);
}

pub fn main() !void {
    c.btstack_memory_init();
    c.btstack_run_loop_init(c.btstack_run_loop_posix_get_instance());
    c.hci_init(c.hci_transport_usb_instance(), null);

    // inform about BTstack state
    hci_event_callback_registration.callback = &state_packet_handler;
    c.hci_add_event_handler(&hci_event_callback_registration);

    // register callback for CTRL-c
    c.btstack_signal_register_callback(c.SIGINT, &trigger_shutdown);
    c.l2cap_init();

    // setup SM: Display only
    c.sm_init();

    gatt.init();

    // uint16_t realtek_num_controllers = btstack_chipset_realtek_get_num_usb_controllers();
    _ = c.hci_power_control(c.HCI_POWER_ON);

    // go
    c.btstack_run_loop_execute();
}

test {
    var a: [16]u8 = undefined;
    a = std.mem.zeroes([16]u8);
    try std.testing.expectEqual(a.len, a[0..16].len);
}
