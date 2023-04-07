const std = @import("std");
const c = @cImport({
    @cInclude("btstack_config.h");

    @cInclude("ble/le_device_db_tlv.h");
    @cInclude("bluetooth_company_id.h");
    // @cInclude("btstack_audio.h");
    // @cInclude("btstack_chipset_realtek.h");
    // @cInclude("btstack_chipset_zephyr.h");
    @cInclude("btstack_debug.h");
    @cInclude("btstack_event.h");
    @cInclude("btstack_memory.h");
    @cInclude("btstack_run_loop.h");
    @cInclude("btstack_run_loop_posix.h");
    @cInclude("btstack_signal.h");
    @cInclude("btstack_stdin.h");
    @cInclude("btstack_tlv_posix.h");

    // @cInclude("classic/btstack_link_key_db_tlv.h");
    @cInclude("hci.h");
    @cInclude("hci_dump.h");
    @cInclude("hci_dump_posix_fs.h");
    @cInclude("hci_transport.h");
    @cInclude("hci_transport_usb.h");
    @cInclude("gap.h");
    @cInclude("att_server.h");
    @cInclude("coneRGB-gatt.h");
    @cInclude("bluetooth_data_types.h");
    @cInclude("ble/gatt-service/device_information_service_server.h");

    @cInclude("signal.h");
});

const local_name: [:0]const u8 = "coneRGB";
var adv_data = [_:0]u8{} ++
    // type flags
    .{
    // Flags general discoverable
    0x02, c.BLUETOOTH_DATA_TYPE_FLAGS, 0x06,
} ++
    // Name
    .{ local_name.len, c.BLUETOOTH_DATA_TYPE_COMPLETE_LOCAL_NAME } ++ local_name ++
    // Incomplete List of 16-bit Service Class UUIDs -- FF10 - only valid for testing!
    .{ 0x03, c.BLUETOOTH_DATA_TYPE_INCOMPLETE_LIST_OF_16_BIT_SERVICE_CLASS_UUIDS, 0x10, 0x69 };

var tlv_db_path: [:0]const u8 = "tlv.db";
var tlv_reset: bool = undefined;
var tlv_impl: [*c]const c.btstack_tlv_t = undefined;
var tlv_context: c.btstack_tlv_posix_t = undefined;
var local_addr: c.bd_addr_t = undefined;

pub fn packet_handler(packet_type: u8, channel: u16, packet: [*c]u8, size: u16) callconv(.C) void {
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

                std.log.info("HCI_STATE_WORKING\n", .{});
            },
            c.HCI_STATE_OFF => {
                std.log.info("HCI_STATE_OFF", .{});
                std.os.exit(0);
            },
            else => {},
        },
        else => {},
    }
}

var hci_event_callback_registration: c.btstack_packet_callback_registration_t = undefined;

pub fn trigger_shutdown() callconv(.C) void {
    _ = c.hci_power_control(c.HCI_POWER_OFF);
}

var counter_string = std.mem.zeroes([30]u8);

pub fn att_read_callback(connection_handle: c.hci_con_handle_t, att_handle: u16, offset: u16, buffer: [*c]u8, buffer_size: u16) callconv(.C) u16 {
    _ = buffer_size;
    _ = buffer;
    _ = offset;
    _ = att_handle;
    _ = connection_handle;
    // if (att_handle == c.ATT_CHARACTERISTIC_0000FF11_0000_1000_8000_00805F9B34FB_01_VALUE_HANDLE) {
    //     return c.att_read_callback_handle_blob(&counter_string, counter_string.len, offset, buffer, buffer_size);
    // }
    return 0;
}

pub fn att_write_callback(connection_handle: c.hci_con_handle_t, att_handle: u16, transaction_mode: u16, offset: u16, buffer: [*c]u8, buffer_size: u16) callconv(.C) c_int {
    _ = buffer_size;
    _ = buffer;
    _ = offset;
    _ = transaction_mode;
    _ = att_handle;
    _ = connection_handle;
    return 0;
}

pub fn main() !void {
    c.btstack_memory_init();
    c.btstack_run_loop_init(c.btstack_run_loop_posix_get_instance());
    c.device_information_service_server_init();
    c.device_information_service_server_set_manufacturer_name("cone.codes");
    c.device_information_service_server_set_model_number("coneRGB");
    c.device_information_service_server_set_serial_number("12345678");
    c.device_information_service_server_set_hardware_revision("2");
    c.device_information_service_server_set_firmware_revision("v0.0.1");
    c.device_information_service_server_set_software_revision("-alpha");
    c.hci_init(c.hci_transport_usb_instance(), null);

    // inform about BTstack state
    hci_event_callback_registration.callback = &packet_handler;
    c.hci_add_event_handler(&hci_event_callback_registration);

    // register callback for CTRL-c
    c.btstack_signal_register_callback(c.SIGINT, &trigger_shutdown);
    c.l2cap_init();

    // setup SM: Display only
    c.sm_init();

    // setup ATT server
    c.att_server_init(&c.profile_data, att_read_callback, att_write_callback);

    // setup advertisements
    var adv_int_min: u16 = 0x0030;
    var adv_int_max: u16 = 0x0030;
    var adv_type: u8 = 0;
    var null_addr: c.bd_addr_t = undefined;
    c.gap_advertisements_set_params(adv_int_min, adv_int_max, adv_type, 0, &null_addr, 0x07, 0x00);
    c.gap_advertisements_set_data(adv_data.len, @ptrCast([*c]u8, &adv_data));
    c.gap_advertisements_enable(1);

    // register for HCI events
    hci_event_callback_registration.callback = &packet_handler;
    c.hci_add_event_handler(&hci_event_callback_registration);

    // register for ATT event
    c.att_server_register_packet_handler(packet_handler);

    // // set one-shot timer
    // heartbeat.process = &heartbeat_handler;
    // btstack_run_loop_set_timer(&heartbeat, HEARTBEAT_PERIOD_MS);
    // btstack_run_loop_add_timer(&heartbeat);

    // uint16_t realtek_num_controllers = btstack_chipset_realtek_get_num_usb_controllers();
    _ = c.hci_power_control(c.HCI_POWER_ON);

    // go
    c.btstack_run_loop_execute();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
