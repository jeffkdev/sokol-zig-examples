const std = @import("std");
const builtin = @import("builtin");

const build_root = "../build/";

const is_windows = std.Target.current.os.tag == .windows;

pub fn build(b: *std.build.Builder) anyerror!void {
    b.release_mode = builtin.Mode.Debug;
    const mode = b.standardReleaseOptions();

    // Probably can take command line arg to build different examples
    // For now rename the mainFile const below (ex: "example_triangle.zig")
    const mainFile = "example_imgui.zig";
    var exe = b.addExecutable("program", "../src/" ++ mainFile);
    exe.addIncludeDir("../src/");
    exe.setBuildMode(mode);
    exe.addCSourceFile("../src/compile_sokol.c", &[_][]const u8{"-std=c99"});

    const cpp_args = [_][]const u8{"-Wno-return-type-c-linkage"};
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
