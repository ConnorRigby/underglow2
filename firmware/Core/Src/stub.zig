const std = @import("std");
const std_thread = @import("std");
const Thread = std_thread.Thread;
const Mutex = Thread.Mutex;

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
var fps_timer: c.btstack_timer_source_t = undefined;

const ChannelState = @import("channel.zig");
const DigitalInputState = @import("digital_input.zig");
const sync = @import("sync.zig");

var channel1_state: ChannelState = .{};
var channel2_state: ChannelState = .{};
var sync_state: ?sync.Sync = null;

var digital_input1_needs_service: bool = false;
var digital_input2_needs_service: bool = false;
var digital_input3_needs_service: bool = false;
var digital_input4_needs_service: bool = false;

var digital_input1: DigitalInputState = .{ .needs_service = &digital_input1_needs_service };
var digital_input2: DigitalInputState = .{ .needs_service = &digital_input2_needs_service };
var digital_input3: DigitalInputState = .{ .needs_service = &digital_input3_needs_service };
var digital_input4: DigitalInputState = .{ .needs_service = &digital_input4_needs_service };

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
                std.log.info("HCI_STATE_WORKING\n", .{});
            },
            c.HCI_STATE_OFF => {
                std.log.info("HCI_STATE_OFF\n", .{});
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

// var ds: c.btstack_data_source = undefined;
// pub fn state_run(data_source: [*c]c.btstack_data_source, callback_type: c.btstack_data_source_callback_type_t) callconv(.C) void {
// _ = callback_type;
// _ = data_source;
pub fn state_run(timer: [*c]c.btstack_timer_source_t) callconv(.C) void {
    _ = timer;
    context.mut.lock();

    channel1_state.state_run();
    channel2_state.state_run();
    digital_input1.state_run();
    digital_input2.state_run();
    digital_input3.state_run();
    digital_input4.state_run();
    if (sync_state) |*s| s.state_run();

    // c.btstack_run_loop_poll_data_sources_from_irq();
    // re-register timer
    c.btstack_run_loop_set_timer(&fps_timer, 33);
    c.btstack_run_loop_add_timer(&fps_timer);
    context.mut.unlock();
}

pub fn btstack_main() !void {
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

    // c.btstack_run_loop_set_data_source_handler(&ds, &state_run);
    // c.btstack_run_loop_enable_data_source_callbacks(&ds, c.DATA_SOURCE_CALLBACK_POLL);
    // c.btstack_run_loop_add_data_source(&ds);

    // set one-shot timer
    fps_timer.process = &state_run;
    c.btstack_run_loop_set_timer(&fps_timer, 33);
    c.btstack_run_loop_add_timer(&fps_timer);

    // uint16_t realtek_num_controllers = btstack_chipset_realtek_get_num_usb_controllers();
    _ = c.hci_power_control(c.HCI_POWER_ON);
}

const builtin = @import("builtin");

const glfw = @import("glfw");
const zgl = @import("zgl");
const zlm = @import("zlm");

pub const cimgui = @cImport({
    @cInclude("stdint.h");
    @cInclude("stdlib.h");
    @cInclude("stdarg.h");
    @cInclude("cimgui.h");
});
extern fn _configure_theme() void;

pub const imgui_impl_glfw = struct {
    pub extern fn ImGui_ImplGlfw_InitForOpenGL(window: ?*anyopaque, install_callbacks: bool) callconv(.C) bool;
    pub extern fn ImGui_ImplGlfw_NewFrame() callconv(.C) void;
    pub extern fn ImGui_ImplGlfw_Shutdown() callconv(.C) void;
};

pub const imgui_impl_opengl3 = struct {
    pub extern fn ImGui_ImplOpenGL3_Init(version: ?*anyopaque) callconv(.C) bool;
    pub extern fn ImGui_ImplOpenGL3_NewFrame() callconv(.C) void;
    pub extern fn ImGui_ImplOpenGL3_RenderDrawData(draw_data: ?*anyopaque) callconv(.C) void;
    pub extern fn ImGui_ImplOpenGL3_Shutdown() callconv(.C) void;
};

const Context = struct {
    start_wait_event: Thread.ResetEvent = .{},
    trigger_event: Thread.ResetEvent = .{},
    thread_done_event: Thread.ResetEvent = .{},
    mut: Thread.Mutex = .{},

    done: std.atomic.Atomic(bool) = std.atomic.Atomic(bool).init(false),
    thread: Thread = undefined,

    pub fn run(ctx: *@This()) !void {
        // Wait for the main thread to have set the thread field in the context.
        ctx.start_wait_event.wait();
        // std.log.info("thread exit", .{});
        // std.os.exit(1);
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        }
        defer glfw.terminate();

        // Create our window
        const window = glfw.Window.create(640, 480, "coneRGB Tester", null, null, .{ .context_version_major = 4, .context_version_minor = 0, .opengl_profile = .opengl_core_profile }) orelse {
            std.log.err("failed to create window: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
            unreachable;
        };
        defer window.destroy();
        glfw.makeContextCurrent(window);

        const proc: glfw.GLProc = undefined;
        try zgl.loadExtensions(proc, glGetProcAddress);
        glfw.swapInterval(1);

        const imgui_context: ?*cimgui.ImGuiContext = cimgui.ImGui_CreateContext(null);
        if (imgui_context == null) return;
        var io: ?*cimgui.ImGuiIO = cimgui.ImGui_GetIO();
        io.?.ConfigFlags |= cimgui.ImGuiConfigFlags_NavEnableKeyboard;
        io.?.ConfigFlags |= cimgui.ImGuiConfigFlags_DockingEnable;
        if (builtin.os.tag == .windows) io.?.ConfigFlags |= cimgui.ImGuiConfigFlags_ViewportsEnable;
        cimgui.ImGui_StyleColorsDark(null);
        _configure_theme();

        if (imgui_impl_glfw.ImGui_ImplGlfw_InitForOpenGL(window.handle, true) == false)
            return;

        if (imgui_impl_opengl3.ImGui_ImplOpenGL3_Init(null) == false)
            return;

        var showDemoWindow: bool = true;
        var windowDimensions: glfw.Window.Size = undefined;
        windowDimensions = window.getFramebufferSize();

        std.log.info("entering UI loop", .{});
        var input1_triggered = false;
        var input1_mode = if (digital_input1.mode) |m| @intCast(c_int, @enumToInt(m)) else @as(c_int, 0);
        var input1_mode_change = false;
        var input1_pattern = if (digital_input1.pattern) |p| @intCast(c_int, @enumToInt(p)) else @as(c_int, 0);
        var input1_pattern_change = false;
        var input1_channel = if (digital_input1.channel_id) |ch| @intCast(c_int, @enumToInt(ch)) else @as(c_int, 0);
        var input1_channel_change = false;

        var input2_triggered = false;
        var input2_mode = if (digital_input2.mode) |m| @intCast(c_int, @enumToInt(m)) else @as(c_int, 0);
        var input2_mode_change = false;
        var input2_pattern = if (digital_input2.pattern) |p| @intCast(c_int, @enumToInt(p)) else @as(c_int, 0);
        var input2_pattern_change = false;
        var input2_channel = if (digital_input2.channel_id) |ch| @intCast(c_int, @enumToInt(ch)) else @as(c_int, 0);
        var input2_channel_change = false;

        var input3_triggered = false;
        var input3_mode = if (digital_input3.mode) |m| @intCast(c_int, @enumToInt(m)) else @as(c_int, 0);
        var input3_mode_change = false;
        var input3_pattern = if (digital_input3.pattern) |p| @intCast(c_int, @enumToInt(p)) else @as(c_int, 0);
        var input3_pattern_change = false;
        var input3_channel = if (digital_input3.channel_id) |ch| @intCast(c_int, @enumToInt(ch)) else @as(c_int, 0);
        var input3_channel_change = false;

        var input4_triggered = false;
        var input4_mode = if (digital_input4.mode) |m| @intCast(c_int, @enumToInt(m)) else @as(c_int, 0);
        var input4_mode_change = false;
        var input4_pattern = if (digital_input4.pattern) |p| @intCast(c_int, @enumToInt(p)) else @as(c_int, 0);
        var input4_pattern_change = false;
        var input4_channel = if (digital_input4.channel_id) |ch| @intCast(c_int, @enumToInt(ch)) else @as(c_int, 0);
        var input4_channel_change = false;

        var rgb_buffer1 = try std.heap.c_allocator.alloc(u32, channel1_state.pixel_buffer.len);
        defer std.heap.c_allocator.free(rgb_buffer1);
        var rgb1: u32 = 0;
        var channel1_current_pattern = channel1_state.get_current_pattern();
        var channel1_pattern_change = false;
        var channel1_pattern = if (channel1_state.pattern) |p| switch (p) {
            .off, .rainbow, .snake, .fill => @intCast(c_int, @enumToInt(@as(ChannelState.Pattern, channel1_state.pattern.?))),
            else => @as(c_int, 0),
        } else @as(c_int, 0);

        var rgb_buffer2 = try std.heap.c_allocator.alloc(u32, channel2_state.pixel_buffer.len);
        defer std.heap.c_allocator.free(rgb_buffer2);
        var rgb2: u32 = 0;
        var channel2_current_pattern = channel2_state.get_current_pattern();
        var channel2_pattern_change = false;
        var channel2_pattern = if (channel2_state.pattern) |p| switch (p) {
            .off, .rainbow, .snake, .fill => @intCast(c_int, @enumToInt(@as(ChannelState.Pattern, channel2_state.pattern.?))),
            else => @as(c_int, 0),
        } else @as(c_int, 0);

        // Wait for the user to close the window.
        while (!window.shouldClose()) {
            if (context.mut.tryLock()) {
                if (input1_mode_change) {
                    input1_mode_change = false;
                    digital_input1.mode = @intToEnum(DigitalInputState.Mode, input1_mode);
                } else if (digital_input1.mode) |m| {
                    input1_mode = @intCast(c_int, @enumToInt(m));
                } else input1_mode = 0;

                if (input1_pattern_change) {
                    input1_pattern_change = false;
                    digital_input1.pattern = @intToEnum(ChannelState.Pattern, input1_pattern);
                } else if (digital_input1.pattern) |p| {
                    input1_pattern = @intCast(c_int, @enumToInt(p));
                } else input1_pattern = 0;

                if (input1_channel_change) {
                    input1_channel_change = false;
                    if (input1_channel == 1) {
                        digital_input1.channel = &channel1_state;
                        digital_input1.channel_id = .channel1;
                    } else if (input1_channel == 2) {
                        digital_input1.channel = &channel2_state;
                        digital_input2.channel_id = .channel2;
                    } else {
                        digital_input1.channel = null;
                        digital_input1.channel_id = null;
                    }
                } else if (digital_input1.channel_id) |ch| {
                    input1_channel = @intCast(c_int, @enumToInt(ch));
                } else input1_channel = 0;

                if (input1_triggered) {
                    std.log.info("input1_triggered", .{});
                    digital_input1_needs_service = true;
                    input1_triggered = false;
                }

                if (input2_mode_change) {
                    input2_mode_change = false;
                    digital_input2.mode = @intToEnum(DigitalInputState.Mode, input2_mode);
                } else if (digital_input2.mode) |m| {
                    input2_mode = @intCast(c_int, @enumToInt(m));
                } else input2_mode = 0;

                if (input2_pattern_change) {
                    input2_pattern_change = false;
                    digital_input2.pattern = @intToEnum(ChannelState.Pattern, input2_pattern);
                } else if (digital_input2.pattern) |p| {
                    input2_pattern = @intCast(c_int, @enumToInt(p));
                } else input2_pattern = 0;

                if (input2_channel_change) {
                    input2_channel_change = false;
                    if (input2_channel == 1) {
                        digital_input2.channel = &channel1_state;
                        digital_input2.channel_id = .channel1;
                    } else if (input2_channel == 2) {
                        digital_input2.channel = &channel2_state;
                        digital_input2.channel_id = .channel2;
                    } else {
                        digital_input2.channel = null;
                        digital_input2.channel_id = null;
                    }
                } else if (digital_input2.channel_id) |ch| {
                    input2_channel = @intCast(c_int, @enumToInt(ch));
                } else input2_channel = 0;

                if (input2_triggered) {
                    digital_input2_needs_service = true;
                    input2_triggered = false;
                }

                if (input3_mode_change) {
                    input3_mode_change = false;
                    digital_input3.mode = @intToEnum(DigitalInputState.Mode, input3_mode);
                } else if (digital_input3.mode) |m| {
                    input3_mode = @intCast(c_int, @enumToInt(m));
                } else input3_mode = 0;

                if (input3_pattern_change) {
                    input3_pattern_change = false;
                    digital_input3.pattern = @intToEnum(ChannelState.Pattern, input3_pattern);
                } else if (digital_input3.pattern) |p| {
                    input3_pattern = @intCast(c_int, @enumToInt(p));
                } else input3_pattern = 0;

                if (input3_channel_change) {
                    input3_channel_change = false;
                    if (input3_channel == 1) {
                        digital_input3.channel = &channel1_state;
                        digital_input3.channel_id = .channel1;
                    } else if (input3_channel == 2) {
                        digital_input3.channel = &channel2_state;
                        digital_input3.channel_id = .channel2;
                    } else {
                        digital_input3.channel = null;
                        digital_input3.channel_id = null;
                    }
                } else if (digital_input3.channel_id) |ch| {
                    input3_channel = @intCast(c_int, @enumToInt(ch));
                } else input3_channel = 0;

                if (input3_triggered) {
                    digital_input3_needs_service = true;
                    input3_triggered = false;
                }

                if (input4_mode_change) {
                    input4_mode_change = false;
                    digital_input4.mode = @intToEnum(DigitalInputState.Mode, input4_mode);
                } else if (digital_input4.mode) |m| {
                    input4_mode = @intCast(c_int, @enumToInt(m));
                } else input4_mode = 0;

                if (input4_pattern_change) {
                    input4_pattern_change = false;
                    digital_input4.pattern = @intToEnum(ChannelState.Pattern, input4_pattern);
                } else if (digital_input4.pattern) |p| {
                    input4_pattern = @intCast(c_int, @enumToInt(p));
                } else input4_pattern = 0;

                if (input4_channel_change) {
                    input4_channel_change = false;
                    if (input4_channel == 1) {
                        digital_input4.channel = &channel1_state;
                        digital_input4.channel_id = .channel1;
                    } else if (input4_channel == 2) {
                        digital_input4.channel = &channel2_state;
                        digital_input2.channel_id = .channel2;
                    } else {
                        digital_input4.channel = null;
                        digital_input4.channel_id = null;
                    }
                } else if (digital_input4.channel_id) |ch| {
                    input4_channel = @intCast(c_int, @enumToInt(ch));
                } else input4_channel = 0;

                if (input4_triggered) {
                    digital_input4_needs_service = true;
                    input4_triggered = false;
                }

                for (rgb_buffer1, 0..rgb_buffer1.len) |_, i| rgb_buffer1[i] = channel1_state.pixel_buffer[i].raw;
                rgb1 = channel1_state.rgb.raw;
                channel1_current_pattern = if (channel1_state.get_current_pattern()) |p| switch (p) {
                    .off, .rainbow, .snake, .fill => @as(ChannelState.Pattern, p),
                    else => null,
                } else null;

                if (channel1_pattern_change) {
                    channel1_pattern_change = false;
                    switch (@intToEnum(ChannelState.Pattern, channel1_pattern)) {
                        .off => channel1_state.pattern = .{ .off = {} },
                        .rainbow => channel1_state.pattern = .{ .rainbow = .{} },
                        .snake => channel1_state.pattern = .{ .snake = .{} },
                        .fill => channel1_state.pattern = .{ .fill = .{} },
                        else => unreachable,
                    }
                } else {
                    channel1_pattern = if (channel1_state.pattern) |p| switch (p) {
                        .off, .rainbow, .snake, .fill => @intCast(c_int, @enumToInt(@as(ChannelState.Pattern, channel1_state.pattern.?))),
                        else => @as(c_int, 0),
                    } else @as(c_int, 0);
                }

                for (rgb_buffer1, 0..rgb_buffer1.len) |_, i| rgb_buffer2[i] = channel2_state.pixel_buffer[i].raw;
                rgb2 = channel2_state.rgb.raw;
                channel2_current_pattern = if (channel2_state.get_current_pattern()) |p| switch (p) {
                    .off, .rainbow, .snake, .fill => @as(ChannelState.Pattern, p),
                    else => null,
                } else null;

                if (channel2_pattern_change) {
                    channel2_pattern_change = false;
                    switch (@intToEnum(ChannelState.Pattern, channel2_pattern)) {
                        .off => channel2_state.pattern = .{ .off = {} },
                        .rainbow => channel2_state.pattern = .{ .rainbow = .{} },
                        .snake => channel2_state.pattern = .{ .snake = .{} },
                        .fill => channel2_state.pattern = .{ .fill = .{} },
                        else => unreachable,
                    }
                } else {
                    channel2_pattern = if (channel2_state.pattern) |p| switch (p) {
                        .off, .rainbow, .snake, .fill => @intCast(c_int, @enumToInt(@as(ChannelState.Pattern, channel2_state.pattern.?))),
                        else => @as(c_int, 0),
                    } else @as(c_int, 0);
                }

                context.mut.unlock();
            }
            glfw.pollEvents();

            windowDimensions = window.getFramebufferSize();

            imgui_impl_opengl3.ImGui_ImplOpenGL3_NewFrame();
            imgui_impl_glfw.ImGui_ImplGlfw_NewFrame();
            cimgui.ImGui_NewFrame();
            _ = cimgui.ImGui_DockSpaceOverViewport();
            if (showDemoWindow) cimgui.ImGui_ShowDemoWindow(&showDemoWindow);
            if (cimgui.ImGui_Begin("RGB Tester", null, cimgui.ImGuiWindowFlags_HorizontalScrollbar | cimgui.ImGuiWindowFlags_MenuBar)) {
                if (cimgui.ImGui_BeginTable("DigitalInput", 4, cimgui.ImGuiTableFlags_Borders)) {
                    for (1..5) |index| {
                        _ = cimgui.ImGui_TableNextColumn();
                        cimgui.ImGui_Text("Input%d", index);
                    }
                    cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    if (digital_input1.needs_service.*) cimgui.ImGui_Text("Input 1 Needs Service") else cimgui.ImGui_Text("Input 1 inactive");
                    _ = cimgui.ImGui_TableNextColumn();
                    if (digital_input2.needs_service.*) cimgui.ImGui_Text("Input 2 Needs Service") else cimgui.ImGui_Text("Input 2 inactive");
                    _ = cimgui.ImGui_TableNextColumn();
                    if (digital_input3.needs_service.*) cimgui.ImGui_Text("Input 3 Needs Service") else cimgui.ImGui_Text("Input 3 inactive");
                    _ = cimgui.ImGui_TableNextColumn();
                    if (digital_input4.needs_service.*) cimgui.ImGui_Text("Input 4 Needs Service") else cimgui.ImGui_Text("Input 4 inactive");

                    cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    input1_mode_change = cimgui.ImGui_Combo("Input 1 Mode", @ptrCast(*c_int, &input1_mode), @tagName(DigitalInputState.Mode.disabled) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_start) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_stop) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_next) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_prev) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_trigger) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input2_mode_change = cimgui.ImGui_Combo("Input 2 Mode", @ptrCast(*c_int, &input2_mode), @tagName(DigitalInputState.Mode.disabled) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_start) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_stop) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_next) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_prev) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_trigger) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input3_mode_change = cimgui.ImGui_Combo("Input 3 Mode", @ptrCast(*c_int, &input3_mode), @tagName(DigitalInputState.Mode.disabled) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_start) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_stop) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_next) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_prev) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_trigger) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input4_mode_change = cimgui.ImGui_Combo("Input 4 Mode", @ptrCast(*c_int, &input4_mode), @tagName(DigitalInputState.Mode.disabled) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_start) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_stop) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_next) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_prev) ++ .{0} ++
                        @tagName(DigitalInputState.Mode.pattern_trigger) ++ .{0});

                    cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    input1_pattern_change = cimgui.ImGui_Combo("Input 1 Pattern", @ptrCast(*c_int, &input1_pattern), @tagName(ChannelState.Pattern.off) ++ .{0} ++
                        @tagName(ChannelState.Pattern.rainbow) ++ .{0} ++
                        @tagName(ChannelState.Pattern.snake) ++ .{0} ++
                        @tagName(ChannelState.Pattern.fill) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input2_pattern_change = cimgui.ImGui_Combo("Input 2 Pattern", @ptrCast(*c_int, &input2_pattern), @tagName(ChannelState.Pattern.off) ++ .{0} ++
                        @tagName(ChannelState.Pattern.rainbow) ++ .{0} ++
                        @tagName(ChannelState.Pattern.snake) ++ .{0} ++
                        @tagName(ChannelState.Pattern.fill) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input3_pattern_change = cimgui.ImGui_Combo("Input 3 Pattern", @ptrCast(*c_int, &input3_pattern), @tagName(ChannelState.Pattern.off) ++ .{0} ++
                        @tagName(ChannelState.Pattern.rainbow) ++ .{0} ++
                        @tagName(ChannelState.Pattern.snake) ++ .{0} ++
                        @tagName(ChannelState.Pattern.fill) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input4_pattern_change = cimgui.ImGui_Combo("Input 4 Pattern", @ptrCast(*c_int, &input4_pattern), @tagName(ChannelState.Pattern.off) ++ .{0} ++
                        @tagName(ChannelState.Pattern.rainbow) ++ .{0} ++
                        @tagName(ChannelState.Pattern.snake) ++ .{0} ++
                        @tagName(ChannelState.Pattern.fill) ++ .{0});

                    cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    input1_channel_change = cimgui.ImGui_Combo("Input 1 Channel", @ptrCast(*c_int, &input1_channel), "Disabled" ++ .{0} ++
                        @tagName(DigitalInputState.ChannelId.channel1) ++ .{0} ++
                        @tagName(DigitalInputState.ChannelId.channel2) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input2_channel_change = cimgui.ImGui_Combo("Input 2 Channel", @ptrCast(*c_int, &input2_channel), "Disabled" ++ .{0} ++
                        @tagName(DigitalInputState.ChannelId.channel1) ++ .{0} ++
                        @tagName(DigitalInputState.ChannelId.channel2) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input3_channel_change = cimgui.ImGui_Combo("Input 3 Channel", @ptrCast(*c_int, &input3_channel), "Disabled" ++ .{0} ++
                        @tagName(DigitalInputState.ChannelId.channel1) ++ .{0} ++
                        @tagName(DigitalInputState.ChannelId.channel2) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    input4_channel_change = cimgui.ImGui_Combo("Input 4 Channel", @ptrCast(*c_int, &input4_channel), "Disabled" ++ .{0} ++
                        @tagName(DigitalInputState.ChannelId.channel1) ++ .{0} ++
                        @tagName(DigitalInputState.ChannelId.channel2) ++ .{0});

                    cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    if (cimgui.ImGui_Button("Input 1 Trigger")) input1_triggered = true;
                    _ = cimgui.ImGui_TableNextColumn();
                    if (cimgui.ImGui_Button("Input 2 Trigger")) input2_triggered = true;
                    _ = cimgui.ImGui_TableNextColumn();
                    if (cimgui.ImGui_Button("Input 3 Trigger")) input3_triggered = true;
                    _ = cimgui.ImGui_TableNextColumn();
                    if (cimgui.ImGui_Button("Input 4 Trigger")) input4_triggered = true;

                    cimgui.ImGui_EndTable();
                }

                if (cimgui.ImGui_BeginTable("RGB Channels", @intCast(c_int, rgb_buffer1.len), cimgui.ImGuiTableFlags_Borders)) {
                    cimgui.ImGui_TableNextRow();
                    for (rgb_buffer1, 0..rgb_buffer1.len) |color, n| {
                        _ = cimgui.ImGui_TableSetColumnIndex(@intCast(c_int, n));
                        cimgui.ImGui_Text("%x", color);
                        cimgui.ImGui_TableSetBgColor(cimgui.ImGuiTableBgTarget_CellBg, color, -1);
                    }
                    cimgui.ImGui_TableNextRow();
                    for (rgb_buffer1, 0..rgb_buffer2.len) |_, n| {
                        _ = cimgui.ImGui_TableSetColumnIndex(@intCast(c_int, n));
                        cimgui.ImGui_Text("%x", rgb1);
                        cimgui.ImGui_TableSetBgColor(cimgui.ImGuiTableBgTarget_CellBg, rgb1, -1);
                    }

                    cimgui.ImGui_TableNextRow();
                    for (rgb_buffer1, 0..rgb_buffer2.len) |_, n| {
                        _ = cimgui.ImGui_TableSetColumnIndex(@intCast(c_int, n));
                        cimgui.ImGui_Text("----------");
                        cimgui.ImGui_TableSetBgColor(cimgui.ImGuiTableBgTarget_CellBg, 0, -1);
                    }

                    cimgui.ImGui_TableNextRow();
                    for (rgb_buffer2, 0..rgb_buffer2.len) |color, n| {
                        _ = cimgui.ImGui_TableSetColumnIndex(@intCast(c_int, n));
                        cimgui.ImGui_Text("%x", color);
                        cimgui.ImGui_TableSetBgColor(cimgui.ImGuiTableBgTarget_CellBg, color, -1);
                    }
                    cimgui.ImGui_TableNextRow();
                    for (rgb_buffer2, 0..rgb_buffer2.len) |_, n| {
                        _ = cimgui.ImGui_TableSetColumnIndex(@intCast(c_int, n));
                        cimgui.ImGui_Text("%x", rgb2);
                        cimgui.ImGui_TableSetBgColor(cimgui.ImGuiTableBgTarget_CellBg, rgb2, -1);
                    }

                    cimgui.ImGui_EndTable();
                }
                if (cimgui.ImGui_BeginTable("RGB Channel pattern", 2, cimgui.ImGuiTableFlags_Borders)) {
                    _ = cimgui.ImGui_TableNextColumn();
                    cimgui.ImGui_Text("channel 1 pattern");

                    _ = cimgui.ImGui_TableNextColumn();
                    cimgui.ImGui_Text("channel 2 pattern");

                    _ = cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    channel1_pattern_change = cimgui.ImGui_Combo("Ch1 Pattern", @ptrCast(*c_int, &channel1_pattern), @tagName(ChannelState.Pattern.off) ++ .{0} ++
                        @tagName(ChannelState.Pattern.rainbow) ++ .{0} ++
                        @tagName(ChannelState.Pattern.snake) ++ .{0} ++
                        @tagName(ChannelState.Pattern.fill) ++ .{0});

                    _ = cimgui.ImGui_TableNextColumn();
                    channel2_pattern_change = cimgui.ImGui_Combo("Ch2 Pattern", @ptrCast(*c_int, &channel2_pattern), @tagName(ChannelState.Pattern.off) ++ .{0} ++
                        @tagName(ChannelState.Pattern.rainbow) ++ .{0} ++
                        @tagName(ChannelState.Pattern.snake) ++ .{0} ++
                        @tagName(ChannelState.Pattern.fill) ++ .{0});

                    cimgui.ImGui_EndTable();
                }

                if (cimgui.ImGui_BeginTable("RGB Channel state", 2, cimgui.ImGuiTableFlags_Borders)) {
                    _ = cimgui.ImGui_TableNextColumn();
                    cimgui.ImGui_Text("channel 1 state");

                    _ = cimgui.ImGui_TableNextColumn();
                    cimgui.ImGui_Text("channel 2 state");

                    _ = cimgui.ImGui_TableNextRow();
                    _ = cimgui.ImGui_TableNextColumn();
                    if (channel1_current_pattern) |pattern| switch (pattern) {
                        inline .off, .rainbow, .snake, .fill => |p| cimgui.ImGui_Text("Channel 1 " ++ @tagName(p)),
                        else => cimgui.ImGui_Text("Unknown pattern"),
                    } else cimgui.ImGui_Text("disabled");
                    _ = cimgui.ImGui_TableNextColumn();
                    if (channel2_current_pattern) |pattern| switch (pattern) {
                        inline .off, .rainbow, .snake, .fill => |p| cimgui.ImGui_Text("Channel 2 " ++ @tagName(p)),
                        else => cimgui.ImGui_Text("Unknown pattern"),
                    } else cimgui.ImGui_Text("disabled");

                    cimgui.ImGui_EndTable();
                }
            }
            cimgui.ImGui_End();

            cimgui.ImGui_Render();

            zgl.clearColor(0.3, 0.1, 0.3, 1);
            zgl.clear(.{ .color = true });

            imgui_impl_opengl3.ImGui_ImplOpenGL3_RenderDrawData(cimgui.ImGui_GetDrawData());
            // Update and Render additional Platform Windows
            // (Platform functions may change the current OpenGL context, so we save/restore it to make it easier to paste this code elsewhere.
            //  For this specific demo app we could also call SDL_GL_MakeCurrent(window, gl_context) directly)
            if (io.?.ConfigFlags & cimgui.ImGuiConfigFlags_ViewportsEnable != 0) {
                var backup_current_window = glfw.getCurrentContext();
                cimgui.ImGui_UpdatePlatformWindows();
                cimgui.ImGui_RenderPlatformWindowsDefault();
                glfw.makeContextCurrent(backup_current_window);
            }

            window.swapBuffers();
        }
        imgui_impl_opengl3.ImGui_ImplOpenGL3_Shutdown();
        imgui_impl_glfw.ImGui_ImplGlfw_Shutdown();
        cimgui.ImGui_DestroyContext(null);

        std.log.info("UI thread done", .{});
        _ = c.hci_power_control(c.HCI_POWER_OFF);

        // wait for the thread to property exit
        ctx.thread_done_event.wait();
    }
    fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?*const anyopaque {
        _ = p;
        return glfw.getProcAddress(proc);
    }

    /// Default GLFW error handling callback
    fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
        std.log.err("glfw: {}: {s}\n", .{ error_code, description });
    }
};

pub fn start_ui_thread(ctx: *Context) !Thread {
    return try Thread.spawn(.{}, Context.run, .{ctx});
}

var context = Context{};

pub fn main() !void {
    std.log.info("starting thread", .{});
    context.thread = try start_ui_thread(&context);
    context.start_wait_event.set();

    try btstack_main();
    c.btstack_run_loop_execute();

    context.trigger_event.wait();
}
