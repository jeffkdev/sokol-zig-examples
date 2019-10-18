const std = @import("std");
const c = @import("c.zig");

fn zero_struct(comptime T: type) T {
    var variable: T = undefined;
    @memset(@ptrCast([*]u8, &variable), 0, @sizeOf(T));
    return variable;
}

const NumSamples = 32;
var pass_action: c.sg_pass_action = undefined;
var sample_pos: usize = 0;
var samples: [NumSamples]f32 = undefined;
var even_odd: u32 = 0;

export fn init() void {
    var desc = zero_struct(c.sg_desc);
    c.sg_setup(&desc);

    pass_action = zero_struct(c.sg_pass_action);
    pass_action.colors[0].action = c.SG_ACTION_CLEAR;
    pass_action.colors[0].val = [_]f32{ 1.0, 0.5, 0.0, 1.0 };

    var audio_desc = zero_struct(c.saudio_desc);
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

export fn sokol_main() c.sapp_desc {
    var app_desc = zero_struct(c.sapp_desc);
    app_desc.width = 1280;
    app_desc.height = 720;
    app_desc.init_cb = init;
    app_desc.frame_cb = update;
    app_desc.cleanup_cb = cleanup;
    app_desc.window_title = c"Sound (sokol-zig)";
    return app_desc;
}
