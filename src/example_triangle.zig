const std = @import("std");
const c = @import("c.zig");

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

    var shader_desc = zero_struct(c.sg_shader_desc);

    shader_desc.vs.source =
        c\\#version 330
        c\\layout(location = 0) in vec4 position;
        c\\out vec4 color;
        c\\layout(location = 1) in vec4 color0;
        c\\void main() {
        c\\  gl_Position = position;
        c\\ color = color0;
        c\\};
    ;
    shader_desc.fs.source =
        c\\#version 330
        c\\layout(location = 0) out vec4 frag_color;
        c\\in vec4 color;
        c\\void main() {
        c\\   frag_color = color;
        c\\};
    ;
    shader_desc.attrs = [_]c.sg_shader_attr_desc{
        c.sg_shader_attr_desc{ .name = c"position", .sem_name = c"TEXCOORD", .sem_index = 0 },
        c.sg_shader_attr_desc{ .name = c"color0", .sem_name = c"TEXCOORD", .sem_index = 1 },
    };
    const shader = c.sg_make_shader(&shader_desc);
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
