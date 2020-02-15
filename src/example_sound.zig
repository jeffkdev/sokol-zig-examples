const std = @import("std");
const c = @import("c.zig");

const NumSamples = 32;
var pass_action: c.sg_pass_action = undefined;
var sample_pos: usize = 0;
var samples: [NumSamples]f32 = undefined;
var even_odd: u32 = 0;

export fn init() void {
    var desc = std.mem.zeroes(c.sg_desc);
    c.sg_setup(&desc);

    pass_action = std.mem.zeroes(c.sg_pass_action);
    pass_action.colors[0].action = .SG_ACTION_CLEAR;
    pass_action.colors[0].val = [_]f32{ 1.0, 0.5, 0.0, 1.0 };

    var audio_desc = std.mem.zeroes(c.saudio_desc);
    c.saudio_setup(&audio_desc);
}

export fn update() void {
    c.sg_begin_default_pass(&pass_action, c.sapp_width(), c.sapp_height());
    const num_frames = @intCast(u32,c.saudio_expect());
    var s : f32 = 0.0;
    var i :u32 = 0;
    while (i < num_frames) {
        if (even_odd & (1<<5) != 0) {
            s = 0.05;
        } else {
            s = -0.05;
        }
        even_odd+=1;
        samples[sample_pos] = s;
        sample_pos += 1;
        if (sample_pos == NumSamples) {
            sample_pos = 0;
            _ = c.saudio_push(&samples[0], NumSamples);
        }
        i += 1;
    }
    c.sg_end_pass();
    c.sg_commit();
}

export fn cleanup() void {
    c.saudio_shutdown();
    c.sg_shutdown();
}

pub fn main() void {
    var app_desc = std.mem.zeroes(c.sapp_desc);
    app_desc.width = 1280;
    app_desc.height = 720;
    app_desc.init_cb = init;
    app_desc.frame_cb = update;
    app_desc.cleanup_cb = cleanup;
    app_desc.window_title = "Sound (sokol-zig)";
    _ = c.sapp_run(&app_desc);
}
