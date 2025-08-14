const std = @import("std");
const c = @import("c");

const State = struct {
    pass_action: c.sg_pass_action,
    main_pipeline: c.sg_pipeline,
    main_bindings: c.sg_bindings,
};

var state: State = undefined;

export fn init_cb() void {
    init() catch unreachable;
}
fn init() !void {
    var desc = std.mem.zeroes(c.sg_desc);
    desc.environment = c.sglue_environment();
    c.sg_setup(&desc);

    state.pass_action.colors[0].load_action = c.SG_LOADACTION_CLEAR;

    state.pass_action.colors[0].clear_value = c.sg_color{ .r = 0.2, .g = 0.2, .b = 0.2, .a = 1.0 };
    const vertices = [_]f32{
        // positions     // colors
        0.0,  0.5,  0.5, 1.0, 0.0, 0.0, 1.0,
        0.5,  -0.5, 0.5, 0.0, 1.0, 0.0, 1.0,
        -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0,
    };

    var buffer_desc = std.mem.zeroes(c.sg_buffer_desc);
    buffer_desc.size = vertices.len * @sizeOf(f32);
    buffer_desc.data = .{ .ptr = &vertices, .size = buffer_desc.size };
    buffer_desc.type = c.SG_BUFFERTYPE_VERTEXBUFFER;
    state.main_bindings.vertex_buffers[0] = c.sg_make_buffer(&buffer_desc);

    const shader_desc = @as([*c]const c.sg_shader_desc, @ptrCast(c.triangle_shader_desc(c.sg_query_backend())));
    const shader = c.sg_make_shader(shader_desc);

    var pipeline_desc = std.mem.zeroes(c.sg_pipeline_desc);
    pipeline_desc.layout.attrs[0].format = c.SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[1].format = c.SG_VERTEXFORMAT_FLOAT4;
    pipeline_desc.shader = shader;
    state.main_pipeline = c.sg_make_pipeline(&pipeline_desc);
}

export fn update() void {
    c.sg_begin_pass(&(c.sg_pass){ .action = state.pass_action, .swapchain = c.sglue_swapchain() });
    c.sg_apply_pipeline(state.main_pipeline);
    c.sg_apply_bindings(&state.main_bindings);
    c.sg_draw(0, 3, 1);
    c.sg_end_pass();
    c.sg_commit();
}

export fn cleanup() void {
    c.sg_shutdown();
}

pub fn main() void {
    var app_desc = std.mem.zeroes(c.sapp_desc);
    app_desc.width = 720;
    app_desc.height = 540;
    app_desc.init_cb = init_cb;
    app_desc.frame_cb = update;
    app_desc.cleanup_cb = cleanup;
    app_desc.sample_count = 4;
    app_desc.window_title = "Triangle (sokol-zig)";
    _ = c.sapp_run(&app_desc);
}
