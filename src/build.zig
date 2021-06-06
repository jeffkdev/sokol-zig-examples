const std = @import("std");
const builtin = @import("builtin");

const build_root = "../build/";

const is_windows = std.Target.current.os.tag == .windows;
const is_macos = std.Target.current.os.tag == .macos;

pub fn build(b: *std.build.Builder) anyerror!void {
    b.setPreferredReleaseMode(.Debug);
    const mode = b.standardReleaseOptions();

    // Probably can take command line arg to build different examples
    // For now rename the mainFile const below (ex: "example_triangle.zig")
    const mainFile = "example_triangle.zig";
    var exe = b.addExecutable("program", "../src/" ++ mainFile);
    exe.addIncludeDir("../src/");
    exe.setBuildMode(mode);

    const cFlags = if (is_macos) [_][]const u8{ "-std=c99", "-ObjC", "-fobjc-arc" } else [_][]const u8{"-std=c99"};
    exe.addCSourceFile("../src/compile_sokol.c", &cFlags);

    const cpp_args = [_][]const u8{ "-Wno-deprecated-declarations", "-Wno-return-type-c-linkage", "-fno-exceptions", "-fno-threadsafe-statics" };
    exe.addCSourceFile("../src/cimgui/imgui/imgui.cpp", &cpp_args);
    exe.addCSourceFile("../src/cimgui/imgui/imgui_demo.cpp", &cpp_args);
    exe.addCSourceFile("../src/cimgui/imgui/imgui_draw.cpp", &cpp_args);
    exe.addCSourceFile("../src/cimgui/imgui/imgui_widgets.cpp", &cpp_args);
    exe.addCSourceFile("../src/cimgui/cimgui.cpp", &cpp_args);

    // Shaders
    exe.addCSourceFile("../src/shaders/cube_compile.c", &[_][]const u8{"-std=c99"});
    exe.addCSourceFile("../src/shaders/triangle_compile.c", &[_][]const u8{"-std=c99"});
    exe.addCSourceFile("../src/shaders/instancing_compile.c", &[_][]const u8{"-std=c99"});
    exe.linkLibC();

    if (is_windows) {
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
        exe.enableSystemLinkerHack();
    } else {
        // Not tested
        @panic("OS not supported. Try removing panic in build.zig if you want to test this");
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("GLEW");
    }

    const run_cmd = exe.run();

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
