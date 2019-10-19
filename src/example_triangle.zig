const std = @import("std");
const c = @import("c.zig");
const glsl = @cImport({
    @cInclude("sokol/sokol_gfx.h");
    @cInclude("shaders/triangle.glsl.h");
});

fn zero_struct(comptime T: type) T {
    var variable: T = undefined;
    @memset(@ptrCast([*]u8, &variable), 0, @sizeOf(T));
    return variable;
}

const State = struct {
    pass_action: c.sg_pass_action,
    main_pipeline: c.sg_pipeline,
    main_bindings: c.sg_bindings,
};

var state: State = undefined;

export fn init() void {
    var desc = zero_struct(c.sg_desc);
    c.sg_setup(&desc);

    state.pass_action.colors[0].action = c.SG_ACTION_CLEAR;
    state.pass_action.colors[0].val = [_]f32{ 0.2, 0.2, 0.2, 1.0 };
    const vertices = [_]f32{
        // positions     // colors
        0.0,  0.5,  0.5, 1.0, 0.0, 0.0, 1.0,
        0.5,  -0.5, 0.5, 0.0, 1.0, 0.0, 1.0,
        -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0,
    };

    var buffer_desc = zero_struct(c.sg_buffer_desc);
    buffer_desc.size = vertices.len * @sizeOf(f32);
    buffer_desc.content = &vertices[0];
    buffer_desc.type = c.SG_BUFFERTYPE_VERTEXBUFFER;
    state.main_bindings.vertex_buffers[0] = c.sg_make_buffer(&buffer_desc);

    const shader_desc =  @ptrCast([*c]const c.sg_shader_desc, glsl.triangle_shader_desc());
    const shader = c.sg_make_shader(shader_desc);
    
    var pipeline_desc = zero_struct(c.sg_pipeline_desc);
    pipeline_desc.layout.attrs[0].format = c.SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[1].format = c.SG_VERTEXFORMAT_FLOAT4;
    pipeline_desc.shader = shader;
    state.main_pipeline = c.sg_make_pipeline(&pipeline_desc);
}

export fn update() void {
    const width = c.sapp_width();
    const height = c.sapp_height();
    c.sg_begin_default_pass(&state.pass_action, width, height);
    c.sg_apply_pipeline(state.main_pipeline);
    c.sg_apply_bindings(&state.main_bindings);
    c.sg_draw(0, 3, 1);
    c.sg_end_pass();
    c.sg_commit();
}

export fn cleanup() void {
    c.sg_shutdown();
}

export fn sokol_main() c.sapp_desc {
    var app_desc = zero_struct(c.sapp_desc);
    app_desc.width = 1280;
    app_desc.height = 720;
    app_desc.init_cb = init;
    app_desc.frame_cb = update;
    app_desc.cleanup_cb = cleanup;
    app_desc.window_title = c"Triangle (sokol-zig)";
    return app_desc;
}
