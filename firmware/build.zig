const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "Core",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "Core/Src/stub.zig" },
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    exe.addIncludePath("Lib/btstack/src/");
    exe.addIncludePath("Lib/btstack/src/ble");
    exe.addIncludePath("Lib/btstack/src/ble/gatt-service/");
    exe.addIncludePath("Lib/btstack/platform/posix/");
    exe.addIncludePath("Lib/btstack/3rd-party/micro-ecc/");
    exe.addIncludePath("Core/Src/btstack");
    exe.addIncludePath("Lib/btstack/port/libusb");
    exe.addIncludePath("Core/Inc");
    exe.linkSystemLibrary("libusb-1.0");
    // b.addSystemCommand("python3 Lib/btstack/tool/compile_gatt.py");
    exe.linkLibC();
    exe.addCSourceFiles(&[_][]const u8{
        "Lib/btstack/platform/libusb/hci_transport_h2_libusb.c",
        "Lib/btstack/src/btstack_memory.c",
        "Lib/btstack/src/btstack_linked_list.c",
        "Lib/btstack/src/btstack_memory_pool.c",
        "Lib/btstack/src/btstack_run_loop.c",
        "Lib/btstack/src/btstack_util.c",
        "Lib/btstack/src/ad_parser.c",
        "Lib/btstack/src/hci.c",
        "Lib/btstack/src/hci_cmd.c",
        "Lib/btstack/src/hci_dump.c",
        "Lib/btstack/src/l2cap.c",
        "Lib/btstack/src/l2cap_signaling.c",
        "Lib/btstack/src/btstack_audio.c",
        "Lib/btstack/src/btstack_tlv.c",
        "Lib/btstack/src/btstack_crypto.c",
        "Lib/btstack/3rd-party/micro-ecc/uECC.c",
        "Lib/btstack/src/ble/sm.c",
        "Lib/btstack/src/ble/att_dispatch.c",
        "Lib/btstack/src/ble/att_db.c",
        "Lib/btstack/src/ble/att_server.c",
        "Lib/btstack/src/ble/gatt_client.c",
        "Lib/btstack/src/ble/gatt-service/battery_service_client.c",
        "Lib/btstack/src/ble/gatt-service/device_information_service_client.c",
        "Lib/btstack/src/ble/gatt-service/scan_parameters_service_client.c",
        "Lib/btstack/src/ble/gatt-service/hids_client.c",
        "Lib/btstack/platform/posix/btstack_stdin_posix.c",
        "Lib/btstack/platform/posix/btstack_tlv_posix.c",
        "Lib/btstack/platform/posix/hci_dump_posix_fs.c",
        "Lib/btstack/platform/posix/btstack_run_loop_posix.c",
        "Lib/btstack/src/ble/le_device_db_tlv.c",
        // "Lib/btstack/src/ble/btstack_link_key_db_tlv.c",
        "Lib/btstack/platform/posix/wav_util.c",
        "Lib/btstack/platform/posix/btstack_network_posix.c",
        "Lib/btstack/platform/posix/btstack_audio_portaudio.c",
        "Lib/btstack/chipset/zephyr/btstack_chipset_zephyr.c",
        "Lib/btstack/chipset/realtek/btstack_chipset_realtek.c",
        "Lib/btstack/3rd-party/rijndael/rijndael.c",
        "Lib/btstack/platform/posix/btstack_signal.c",
        "Lib/btstack/src/ble/gatt-service/device_information_service_server.c",
    }, &[_][]const u8{ "-std=c99", "-Wall", "-Wmissing-prototypes", "-Wstrict-prototypes", "-Wshadow", "-Wunused-parameter", "-Wredundant-decls", "-Wsign-compare", "-Wswitch-default" });
    exe.install();

    // This *creates* a RunStep in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = exe.run();

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing.
    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "Core/Src/stub.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
