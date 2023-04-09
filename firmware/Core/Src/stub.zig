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
                digital_input1.mode = .pattern_start;
                digital_input1.pattern = .rainbow;
                digital_input1.channel = &channel1_state;
                digital_input1.channel_id = .channel1;
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

var ds: c.btstack_data_source = undefined;
pub fn state_run(data_source: [*c]c.btstack_data_source, callback_type: c.btstack_data_source_callback_type_t) callconv(.C) void {
    _ = callback_type;
    _ = data_source;
    context.mut.lock();

    channel1_state.state_run();
    channel2_state.state_run();
    digital_input1.state_run();
    digital_input2.state_run();
    digital_input3.state_run();
    digital_input4.state_run();
    if (sync_state) |*s| s.state_run();

    c.btstack_run_loop_poll_data_sources_from_irq();
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

    c.btstack_run_loop_set_data_source_handler(&ds, &state_run);
    c.btstack_run_loop_enable_data_source_callbacks(&ds, c.DATA_SOURCE_CALLBACK_POLL);
    c.btstack_run_loop_add_data_source(&ds);

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
        var input2_triggered = false;
        var input3_triggered = false;
        var input4_triggered = false;

        // Wait for the user to close the window.
        while (!window.shouldClose()) {
            if (context.mut.tryLock()) {
                // std.log.info("lock aquired", .{});
                if (input1_triggered) {
                    std.log.info("input1_triggered", .{});
                    digital_input1_needs_service = true;
                    input1_triggered = false;
                }
                if (input2_triggered) {
                    digital_input2_needs_service = true;
                    input2_triggered = false;
                }
                if (input3_triggered) {
                    digital_input3_needs_service = true;
                    input3_triggered = false;
                }
                if (input4_triggered) {
                    digital_input4_needs_service = true;
                    input4_triggered = false;
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
                if (cimgui.ImGui_BeginTable("table", 4, cimgui.ImGuiTableFlags_Borders)) {
                    for (1..5) |index| {
                        _ = cimgui.ImGui_TableNextColumn();
                        cimgui.ImGui_Text("Input%d", index);
                        // ImGui::Text("Width %.2f", ImGui::GetContentRegionAvail().x);
                    }
                    cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    if (digital_input1.needs_service.*) cimgui.ImGui_Text("Needs Service") else cimgui.ImGui_Text("unread");
                    _ = cimgui.ImGui_TableNextColumn();
                    if (digital_input2.needs_service.*) cimgui.ImGui_Text("Needs Service") else cimgui.ImGui_Text("unread");
                    _ = cimgui.ImGui_TableNextColumn();
                    if (digital_input3.needs_service.*) cimgui.ImGui_Text("Needs Service") else cimgui.ImGui_Text("unread");
                    _ = cimgui.ImGui_TableNextColumn();
                    if (digital_input4.needs_service.*) cimgui.ImGui_Text("Needs Service") else cimgui.ImGui_Text("unread");

                    cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    cimgui.ImGui_Text("mode=%d", if (digital_input1.mode) |m| @enumToInt(m) else 255);
                    _ = cimgui.ImGui_TableNextColumn();
                    cimgui.ImGui_Text("mode=%d", if (digital_input2.mode) |m| @enumToInt(m) else 255);
                    _ = cimgui.ImGui_TableNextColumn();
                    cimgui.ImGui_Text("mode=%d", if (digital_input3.mode) |m| @enumToInt(m) else 255);
                    _ = cimgui.ImGui_TableNextColumn();
                    cimgui.ImGui_Text("mode=%d", if (digital_input4.mode) |m| @enumToInt(m) else 255);

                    cimgui.ImGui_TableNextRow();

                    _ = cimgui.ImGui_TableNextColumn();
                    if (cimgui.ImGui_Button("Trigger")) input1_triggered = true;
                    _ = cimgui.ImGui_TableNextColumn();
                    if (cimgui.ImGui_Button("Trigger")) input2_triggered = true;
                    _ = cimgui.ImGui_TableNextColumn();
                    if (cimgui.ImGui_Button("Trigger")) input3_triggered = true;
                    _ = cimgui.ImGui_TableNextColumn();
                    if (cimgui.ImGui_Button("Trigger")) input4_triggered = true;

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
