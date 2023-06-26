const std = @import("std");
const builtin = @import("builtin");

const build_root = "../build/";

const is_windows = builtin.target.os.tag == .windows;
const is_macos = builtin.target.os.tag == .macos;

pub fn build(b: *std.build.Builder) anyerror!void {
    // Change this to .ReleaseFast, .ReleaseSafe, or .ReleaseSmall to compile in release mode
    const mode: std.builtin.OptimizeMode = .Debug;

    // Previously was exe.enableSystemLinkerHack(): See https://github.com/jeffkdev/sokol-zig-examples/issues/2
    if (is_macos) try b.env_map.put("ZIG_SYSTEM_LINKER_HACK", "1");

    // Probably can take command line arg to build different examples
    // For now rename the main_file to one of the follow:
    //     example_cube.zig, example_imgui.zig, example_instancing.zig, example_sound.zig, example_triangle.zig
    const main_file = "example_imgui.zig";
    var exe = b.addExecutable(
        .{
            .name = "program",
            .root_source_file = .{ .path = main_file },
            .optimize = mode,
        },
    );
    var c_module = b.createModule(.{ .source_file = .{ .path = "c.zig" } });

    exe.addModule("c", c_module);
    exe.addIncludePath("");

    const c_flags = if (is_macos) [_][]const u8{ "-std=c99", "-ObjC", "-fobjc-arc" } else [_][]const u8{"-std=c99"};
    exe.addCSourceFile("compile_sokol.c", &c_flags);

    const cpp_args = [_][]const u8{ "-Wno-deprecated-declarations", "-Wno-return-type-c-linkage", "-fno-exceptions", "-fno-threadsafe-statics" };
    exe.addCSourceFile("cimgui/imgui/imgui.cpp", &cpp_args);
    // Need to add this after updating imgui to 1.80+
    // exe.addCSourceFile("../src/cimgui/imgui/imgui_tables.cpp", &cpp_args);
    exe.addCSourceFile("cimgui/imgui/imgui_demo.cpp", &cpp_args);
    exe.addCSourceFile("cimgui/imgui/imgui_draw.cpp", &cpp_args);
    exe.addCSourceFile("cimgui/imgui/imgui_widgets.cpp", &cpp_args);
    exe.addCSourceFile("cimgui/cimgui.cpp", &cpp_args);

    // Shaders
    exe.addCSourceFile("shaders/cube_compile.c", &[_][]const u8{"-std=c99"});
    exe.addCSourceFile("shaders/triangle_compile.c", &[_][]const u8{"-std=c99"});
    exe.addCSourceFile("shaders/instancing_compile.c", &[_][]const u8{"-std=c99"});
    exe.linkLibC();

    if (is_windows) {
        //See https://github.com/ziglang/zig/issues/8531 only matters in release mode
        exe.want_lto = false;
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("ole32"); // For Sokol audio
    } else if (is_macos) {
        const frameworks_dir = try macos_frameworks_dir(b);
        exe.addFrameworkDir(frameworks_dir);
        exe.linkFramework("Foundation");
        exe.linkFramework("Cocoa");
        exe.linkFramework("Quartz");
        exe.linkFramework("QuartzCore");
        exe.linkFramework("Metal");
        exe.linkFramework("MetalKit");
        exe.linkFramework("OpenGL");
        exe.linkFramework("Audiotoolbox");
        exe.linkFramework("CoreAudio");
        exe.linkSystemLibrary("c++");
    } else {
        // Not tested
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("GLEW");
        @panic("OS not supported. Try removing panic in build.zig if you want to test this");
    }

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}

// helper function to get SDK path on Mac sourced from: https://github.com/floooh/sokol-zig
fn macos_frameworks_dir(b: *std.build.Builder) ![]u8 {
    var str = try b.exec(&[_][]const u8{ "xcrun", "--show-sdk-path" });
    const strip_newline = std.mem.lastIndexOf(u8, str, "\n");
    if (strip_newline) |index| {
        str = str[0..index];
    }
    const frameworks_dir = try std.mem.concat(b.allocator, u8, &[_][]const u8{ str, "/System/Library/Frameworks" });
    return frameworks_dir;
}
