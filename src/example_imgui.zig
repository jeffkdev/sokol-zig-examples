const std = @import("std");
const c = @import("c.zig");

const State = struct {
    pass_action: c.sg_pass_action,
    main_pipeline: c.sg_pipeline,
    main_bindings: c.sg_bindings,
};

var state: State = undefined;
var last_time: u64 = 0;
var show_test_window: bool = false;
var show_another_window: bool = false;
var display_menu: bool = false;
var f: f32 = 0.0;
var clear_color: [3]f32 = .{ 0.2, 0.2, 0.2 };

export fn init() void {
    var desc = std.mem.zeroes(c.sg_desc);
    desc.context = c.sapp_sgcontext();
    c.sg_setup(&desc);
    c.stm_setup();

    var imgui_desc = std.mem.zeroes(c.simgui_desc_t);
    c.simgui_setup(&imgui_desc);

    state.pass_action.colors[0].action = c.SG_ACTION_CLEAR;
    state.pass_action.colors[0].value = c.sg_color{ .r = clear_color[0], .g = clear_color[1], .b = clear_color[2], .a = 1.0 };
}

export fn update() void {
    const width = c.sapp_width();
    const height = c.sapp_height();
    const dt = c.stm_sec(c.stm_laptime(&last_time));
    c.simgui_new_frame(width, height, dt);

    c.igText("Hello, world!");
    _ = c.igSliderFloat("float", &f, 0.0, 1.0, "%.3f", 1.0);
    if (c.igColorEdit3("clear color", &clear_color[0], 0)) {
        state.pass_action.colors[0].value.r = clear_color[0];
        state.pass_action.colors[0].value.g = clear_color[1];
        state.pass_action.colors[0].value.b = clear_color[2];
    }
    if (c.igButton("Test Window", c.ImVec2{ .x = 0.0, .y = 0.0 })) show_test_window = !show_test_window;
    if (c.igButton("Another Window", c.ImVec2{ .x = 0.0, .y = 0.0 })) show_another_window = !show_another_window;
    c.igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / c.igGetIO().*.Framerate, c.igGetIO().*.Framerate);

    if (show_another_window) {
        c.igSetNextWindowSize(c.ImVec2{ .x = 200, .y = 100 }, c.ImGuiCond_FirstUseEver);
        _ = c.igBegin("Another Window", &show_another_window, 0);
        c.igText("Hello");
        c.igEnd();
    }
    var ig_context: *c.ImGuiContext = c.igGetCurrentContext();
    var window: *c.ImGuiWindow = ig_context.*.CurrentWindow.?;
    if (!window.SkipItems) {
        c.igText(
            \\ Translate-c converts c.ImGuiWindow to an opaque type
            \\ in imgui 1.80+ causing this to not compile
        );
    }

    if (show_test_window) {
        c.igSetNextWindowPos(c.ImVec2{ .x = 460, .y = 20 }, c.ImGuiCond_FirstUseEver, c.ImVec2{ .x = 0, .y = 0 });
        c.igShowDemoWindow(0);
    }

    c.sg_begin_default_pass(&state.pass_action, width, height);
    c.simgui_render();
    c.sg_end_pass();
    c.sg_commit();
}

export fn cleanup() void {
    c.simgui_shutdown();
    c.sg_shutdown();
}

export fn event(e: [*c]const c.sapp_event) void {
    _ = c.simgui_handle_event(e);
}

pub fn main() void {
    var app_desc = std.mem.zeroes(c.sapp_desc);
    app_desc.width = 1280;
    app_desc.height = 720;
    app_desc.init_cb = init;
    app_desc.frame_cb = update;
    app_desc.cleanup_cb = cleanup;
    app_desc.event_cb = event;
    app_desc.enable_clipboard = true;
    app_desc.window_title = "IMGUI (sokol-zig)";
    _ = c.sapp_run(&app_desc);
}
