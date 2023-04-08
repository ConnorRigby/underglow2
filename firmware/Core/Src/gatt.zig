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
});

const gatt_profile = @import("coneRGB.gatt.zig");
const sync = @import("sync.zig");

const ChannelState = @import("channel.zig");
const DigitalInputState = @import("digital_input.zig");

pub fn Server(
    comptime channel1_state: *ChannelState,
    comptime channel2_state: *ChannelState,
    comptime sync_state: *?sync.Sync,
    comptime digital_input1_state: *DigitalInputState,
    comptime digital_input2_state: *DigitalInputState,
    comptime digital_input3_state: *DigitalInputState,
    comptime digital_input4_state: *DigitalInputState,
) type {
    return struct {
        const local_name: []const u8 = "coneRGB";
        const incomplete_list_of_16_bit_service_class_uuids = &[_]u8{
            // channel 1
            0x10, 0x69,
            // channel 2
            0x20, 0x69,
            // sync
            0x30, 0x69,
            // digital input 1
            0x41, 0x69,
            // digital input 2
            0x42, 0x69,
            // digital input 3
            0x43, 0x69,
            // digital input 4
            0x44, 0x69,
        };
        var adv_data = [_]u8{} ++
            // type flags
            .{
            // Flags general discoverable
            0x02, c.BLUETOOTH_DATA_TYPE_FLAGS, 0x06,
        } ++
            // Name
            .{ 1 + local_name.len, c.BLUETOOTH_DATA_TYPE_COMPLETE_LOCAL_NAME } ++ local_name ++
            // Incomplete List of 16-bit Service Class UUIDs
            // -- 6910 rgb channel 1
            // -- 6920 rgb channel 2
            // -- 6930 network sync
            .{ 1 + incomplete_list_of_16_bit_service_class_uuids.len, c.BLUETOOTH_DATA_TYPE_INCOMPLETE_LIST_OF_16_BIT_SERVICE_CLASS_UUIDS } ++ incomplete_list_of_16_bit_service_class_uuids;

        pub fn att_read_callback(connection_handle: c.hci_con_handle_t, att_handle: u16, offset: u16, buffer: [*c]u8, buffer_size: u16) callconv(.C) u16 {
            _ = offset;
            _ = connection_handle;
            // std.debug.print("att read handle={x}\n", .{att_handle});
            if (buffer) |b| {
                var slice = b[0..@intCast(usize, buffer_size)];
                if (gatt_profile.Handle.get(att_handle)) |char_handle| switch (char_handle) {
                    .channel1 => |channel_handle| switch (channel_handle) {
                        .nzr => return channel1_state.handle_read_nzr(slice),
                        .rgb => return channel1_state.handle_read_rgb(slice),
                        else => {},
                    },
                    .channel2 => |channel_handle| switch (channel_handle) {
                        .nzr => return channel2_state.handle_read_nzr(slice),
                        .rgb => return channel2_state.handle_read_rgb(slice),
                        else => {},
                    },
                    .digital_input => |input_handle| switch (input_handle) {
                        .digital_input1, .digital_input2, .digital_input3, .digital_input4 => |i| if (i == .digital_input1) {
                            return digital_input1_state.handle_read(slice);
                        } else if (i == .digital_input2) {
                            return digital_input2_state.handle_read(slice);
                        } else if (i == .digital_input3) {
                            return digital_input3_state.handle_read(slice);
                        } else if (i == .digital_input4) {
                            return digital_input4_state.handle_read(slice);
                        } else unreachable,
                    },
                    .sync => |sync_handle| switch (sync_handle) {
                        .network_id => if (sync_state.*) |s| switch (s) {
                            .client => |*node| {
                                std.mem.copy(u8, slice[0..16], &node.network);
                                return slice[0..16].len;
                            },
                            .server => |*node| {
                                std.mem.copy(u8, slice[0..16], &node.network);
                                return slice[0..16].len;
                            },
                        } else {},
                        .role => if (sync_state.*) |s| {
                            std.mem.writeIntLittle(u8, slice[0..1], @enumToInt(@as(sync.State, s)));
                            return slice[0..1].len;
                        } else {
                            std.mem.writeIntLittle(u8, slice[0..1], 255);
                            return slice[0..1].len;
                        },
                        .status => {
                            std.mem.writeIntLittle(u8, slice[0..1], 255);
                            return slice[0..1].len;
                        },
                        .node_id => if (sync_state.*) |s| switch (s) {
                            .client => |n| {
                                std.mem.writeIntLittle(u8, slice[0..1], @enumToInt(n.address));
                                return slice[0..1].len;
                            },
                            .server => |n| {
                                std.mem.writeIntLittle(u8, slice[0..1], @enumToInt(n.address));
                                return slice[0..1].len;
                            },
                        },
                        else => {
                            std.log.err("unhandled sync command: {any}", .{sync_handle});
                        },
                    },
                };
            }
            return 0;
        }

        pub fn att_write_callback(connection_handle: c.hci_con_handle_t, att_handle: u16, transaction_mode: u16, offset: u16, buffer: [*c]u8, buffer_size: u16) callconv(.C) c_int {
            _ = transaction_mode;
            _ = offset;
            _ = connection_handle;
            // std.debug.print("att_write_callback transaction_mode=0x{x}\n", .{transaction_mode});
            if (buffer) |b| {
                var slice = b[0..@intCast(usize, buffer_size)];
                if (gatt_profile.Handle.get(att_handle)) |char_handle| switch (char_handle) {
                    .channel1 => |channel_handle| switch (channel_handle) {
                        .nzr => return channel1_state.handle_write_nzr(slice),
                        .rgb => return channel1_state.handle_write_rgb(slice),
                        else => return 0,
                    },
                    .channel2 => |channel_handle| switch (channel_handle) {
                        .nzr => return channel2_state.handle_write_nzr(slice),
                        .rgb => return channel2_state.handle_write_rgb(slice),
                        else => return 0,
                    },
                    .digital_input => |input_handle| switch (input_handle) {
                        .digital_input1, .digital_input2, .digital_input3, .digital_input4 => |i| if (i == .digital_input1) {
                            return digital_input1_state.handle_write(slice, channel1_state, channel2_state);
                        } else if (i == .digital_input2) {
                            return digital_input2_state.handle_write(slice, channel1_state, channel2_state);
                        } else if (i == .digital_input3) {
                            return digital_input3_state.handle_write(slice, channel1_state, channel2_state);
                        } else if (i == .digital_input4) {
                            return digital_input4_state.handle_write(slice, channel1_state, channel2_state);
                        } else unreachable,
                    },
                    .sync => |sync_handle| switch (sync_handle) {
                        .network_id => if (sync_state.*) |*s| switch (s.*) {
                            .server => |*node| {
                                if (slice.len > 16) return 0;
                                std.mem.copy(u8, &node.network, slice);
                                return 0;
                            },
                            .client => |*node| {
                                if (slice.len > 16) return 0;
                                std.mem.copy(u8, &node.network, slice);
                                return 0;
                            },
                        },
                        .role => switch (@intToEnum(sync.State, std.mem.readIntLittle(u8, slice[0..1]))) {
                            .server => sync_state.* = .{ .server = sync.Server.init(0, .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, .{}) },
                            .client => sync_state.* = .{ .client = sync.Client.init(0, .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, .{}) },
                            else => return 0,
                        },
                        else => {
                            std.log.err("unhandled sync service write: {any}", .{sync_handle});
                            return 0;
                        },
                    },
                } else return 0;
            } else return 0;
            return 0;
        }

        pub fn att_packet_handler(packet_type: u8, channel: u16, packet: [*c]u8, size: u16) callconv(.C) void {
            _ = channel;
            _ = size;
            if (packet_type != c.HCI_EVENT_PACKET) return;
            switch (c.hci_event_packet_get_type(packet)) {
                else => {},
            }
        }

        pub fn init() void {
            // setup ATT server
            c.att_server_init(gatt_profile.profile_data, att_read_callback, att_write_callback);

            c.device_information_service_server_init();
            c.device_information_service_server_set_manufacturer_name("cone.codes");
            c.device_information_service_server_set_model_number("coneRGB");
            c.device_information_service_server_set_serial_number("12345678");
            c.device_information_service_server_set_hardware_revision("2");
            c.device_information_service_server_set_firmware_revision("v0.0.1");
            c.device_information_service_server_set_software_revision("-alpha");

            // setup advertisements
            var adv_int_min: u16 = 0x0030;
            var adv_int_max: u16 = 0x0030;
            var adv_type: u8 = 0;
            var null_addr = std.mem.zeroes(c.bd_addr_t);
            c.gap_advertisements_set_params(adv_int_min, adv_int_max, adv_type, 0, &null_addr, 0x07, 0x00);
            c.gap_advertisements_set_data(adv_data.len, @constCast(adv_data));
            c.gap_advertisements_enable(1);

            // // register for HCI events
            // hci_event_callback_registration.callback = &att_packet_handler;
            // c.hci_add_event_handler(&hci_event_callback_registration);

            // register for ATT event
            c.att_server_register_packet_handler(att_packet_handler);
        }
    };
}
