const std = @import("std");
const builtin = @import("builtin");

const build_root = "../build/";

const is_windows = builtin.os == builtin.Os.windows;

pub fn build(b: *std.build.Builder) anyerror!void {
    b.release_mode = builtin.Mode.Debug;
    const mode = b.standardReleaseOptions();

    // Probably can take command line arg to build different examples
    // For now rename the mainFile const below (ex: "example_triangle.zig")
    const mainFile = "example_cube.zig"; 
    var exe = b.addExecutable("program", "../src/" ++ mainFile);
    exe.addIncludeDir("../src/");
    exe.setBuildMode(mode);
    exe.addCSourceFile("../src/compile_sokol.c", [_][]const u8{"-std=c99"});
    exe.addCSourceFile("../src/compile_glsl.c", [_][]const u8{"-std=c99"});

    exe.linkSystemLibrary("c");
    if (is_windows) {
        exe.addObjectFile(build_root++"cimgui.obj");
        exe.addObjectFile(build_root++"imgui.obj");
        exe.addObjectFile(build_root++"imgui_demo.obj");
        exe.addObjectFile(build_root++"imgui_draw.obj");
        exe.addObjectFile(build_root++"imgui_widgets.obj");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
    } else {
        // Not tested
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("GLEW");
    }
    
    const run_cmd = exe.run();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
