const std = @import("std");
const builtin = @import("builtin");
const Build = std.Build;
const build_root = "../build/";
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;
const emscripten = @import("src/emscripten.zig");

pub fn build(b: *std.Build) anyerror!void {
    // TODO: Use mode from command line args
    // Change this to .ReleaseFast, .ReleaseSafe, or .ReleaseSmall to compile in release mode
    const mode: std.builtin.OptimizeMode = .Debug;
    const target = b.standardTargetOptions(.{});

    // TODO: Use command line arg to build different examples
    // For now rename the main_file to one of the follow:
    //     example_cube.zig, example_imgui.zig, example_instancing.zig, example_sound.zig, example_triangle.zig
    const main_file = "example_cube.zig";
    if (target.result.isWasm()) {
        try buildWeb(b, target, mode, main_file);
    } else {
        var exe = b.addExecutable(
            .{
                .name = "program",
                .root_source_file = b.path("src/" ++ main_file),
                .optimize = mode,
                .target = std.Build.resolveTargetQuery(b, std.Target.Query{}),
            },
        );
        try addImports(b, target, exe, null);
        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
        b.default_step.dependOn(&exe.step);
        b.installArtifact(exe);
    }
}

fn addImports(b: *std.Build, target: Build.ResolvedTarget, exe: *Step.Compile, emsdk: ?*Build.Dependency) !void {
    exe.addIncludePath(b.path("src/"));
    const c_module = b.createModule(.{ .root_source_file = .{ .src_path = .{ .sub_path = "src/c.zig", .owner = b } } });

    exe.root_module.addImport("c", c_module);

    const render_backend_flag = targetToBackendFlag(target.result);

    const c_flags = if (target.result.os.tag == .macos) &[_][]const u8{ "-std=c99", "-ObjC", "-fobjc-arc", render_backend_flag } else &[_][]const u8{ "-std=c99", render_backend_flag };
    exe.addCSourceFile(.{ .file = .{ .src_path = .{ .owner = b, .sub_path = "src/compile_sokol.c" } }, .flags = c_flags });

    const cpp_args = [_][]const u8{ "-Wno-deprecated-declarations", "-Wno-return-type-c-linkage", "-fno-exceptions", "-fno-threadsafe-statics" };
    exe.addCSourceFile(.{ .file = b.path("src/cimgui/imgui/imgui.cpp"), .flags = &cpp_args });
    exe.addCSourceFile(.{ .file = b.path("src/cimgui/imgui/imgui_tables.cpp"), .flags = &cpp_args });
    exe.addCSourceFile(.{ .file = b.path("src/cimgui/imgui/imgui_demo.cpp"), .flags = &cpp_args });
    exe.addCSourceFile(.{ .file = b.path("src/cimgui/imgui/imgui_draw.cpp"), .flags = &cpp_args });
    exe.addCSourceFile(.{ .file = b.path("src/cimgui/imgui/imgui_widgets.cpp"), .flags = &cpp_args });
    exe.addCSourceFile(.{ .file = b.path("src/cimgui/cimgui.cpp"), .flags = &cpp_args });

    // Shaders
    const shader_flags = [_][]const u8{"-std=c99"};
    exe.addCSourceFile(.{ .file = b.path("src/shaders/cube_compile.c"), .flags = &shader_flags });
    exe.addCSourceFile(.{ .file = b.path("src/shaders/triangle_compile.c"), .flags = &shader_flags });
    exe.addCSourceFile(.{ .file = b.path("src/shaders/instancing_compile.c"), .flags = &shader_flags });
    exe.linkLibC();

    switch (target.result.os.tag) {
        .windows => {
            //See https://github.com/ziglang/zig/issues/8531 only matters in release mode
            exe.want_lto = false;
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("ole32"); // For Sokol audio
        },
        .macos => {
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
        },
        .emscripten => {
            // make sure we're building for the wasm32-emscripten target, not wasm32-freestanding
            if (exe.rootModuleTarget().os.tag != .emscripten) {
                std.log.err("Please build with 'zig build -Dtarget=wasm32-emscripten", .{});
                return error.Wasm32EmscriptenExpected;
            }
            // one-time setup of Emscripten SDK
            if (try emscripten.emSdkSetupStep(b, emsdk.?)) |emsdk_setup| {
                exe.step.dependOn(&emsdk_setup.step);
            }
            // add the Emscripten system include seach path
            exe.addSystemIncludePath(emscripten.emSdkLazyPath(b, emsdk.?, &.{ "upstream", "emscripten", "cache", "sysroot", "include" }));
        },
        else => {
            // Not tested
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("GLEW");
            @panic("OS not supported. Try removing panic in build.zig if you want to test this");
        },
    }
}

fn targetToBackendFlag(target: std.Target) []const u8 {
    if (target.isDarwin()) {
        return "-DSOKOL_METAL";
    } else if (target.isWasm() or target.isAndroid()) {
        return "-DSOKOL_GLES3";
    } else {
        return "-DSOKOL_GLCORE";
    }
}

// for web builds, the Zig code needs to be built into a library and linked with the Emscripten linker
fn buildWeb(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode, comptime file_with_extension: []const u8) !void {
    const name = file_with_extension[0 .. file_with_extension.len - 4];
    const game = b.addStaticLibrary(.{
        .name = name,
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/" ++ file_with_extension),
    });
    const emsdk = b.dependency("emsdk", .{});

    try addImports(b, target, game, emsdk);
    // create a build step which invokes the Emscripten linker
    // const emsdk = dep_sokol.builder.dependency("emsdk", .{});
    const link_step = try emscripten.emLinkStep(b, .{
        .lib_main = game,
        .target = target,
        .optimize = optimize,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = false,
        .shell_file_path = b.path("src/web/shell.html"),
        .extra_args = &.{
            // Zig allocators use the @returnAddress builtin, which isn't supported in the Emscripten runtime out of the box
            // (you'll get a runtime error in the browser's Javascript console looking like this: Cannot use convertFrameToPC
            // (needed by __builtin_return_address) without -sUSE_OFFSET_CONVERTER. To make it work, do as the error message says,
            // to add the -sUSE_OFFSET_CONVERTER arg to the Emscripten linker step in your build.zig file:
            "-sUSE_OFFSET_CONVERTER=1",
            // Allow memory growth
            "-sALLOW_MEMORY_GROWTH=1",
            // 1 MB stack to match windows default
            "-sSTACK_SIZE= 1048576",
        },
    });
    // ...and a special run step to start the web build output via 'emrun'
    const run = emscripten.emRunStep(b, .{ .name = name, .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run game").dependOn(&run.step);
}
