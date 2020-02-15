const std = @import("std");
const c = @import("c.zig");
const Mat4 = @import("math3d.zig").Mat4;
const Vec3 = @import("math3d.zig").Vec3;
const glsl = @cImport({
    @cInclude("sokol/sokol_gfx.h");
    @cInclude("shaders/cube.glsl.h");
});

const SampleCount = 4;

const State = struct {
    pass_action: c.sg_pass_action,
    main_pipeline: c.sg_pipeline,
    main_bindings: c.sg_bindings,
};

var rx: f32 = 0.0;
var ry: f32 = 0.0;
var state: State = undefined;

export fn init() void {
    var desc = std.mem.zeroes(c.sg_desc);
    c.sg_setup(&desc);

    c.stm_setup();
    
    state.pass_action.colors[0].action = .SG_ACTION_CLEAR;
    state.pass_action.colors[0].val = [_]f32{ 0.2, 0.2, 0.2, 1.0 };
    const vertices = [_]f32{
        // positions     // colors
        -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
        1.0,  -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
        1.0,  1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,
        -1.0, 1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,

        -1.0, -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
        1.0,  -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
        1.0,  1.0,  1.0,  0.0, 1.0, 0.0, 1.0,
        -1.0, 1.0,  1.0,  0.0, 1.0, 0.0, 1.0,

        -1.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0,
        -1.0, 1.0,  -1.0, 0.0, 0.0, 1.0, 1.0,
        -1.0, 1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
        -1.0, -1.0, 1.0,  0.0, 0.0, 1.0, 1.0,

        1.0,  -1.0, -1.0, 1.0, 0.5, 0.0, 1.0,
        1.0,  1.0,  -1.0, 1.0, 0.5, 0.0, 1.0,
        1.0,  1.0,  1.0,  1.0, 0.5, 0.0, 1.0,
        1.0,  -1.0, 1.0,  1.0, 0.5, 0.0, 1.0,

        -1.0, -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,
        -1.0, -1.0, 1.0,  0.0, 0.5, 1.0, 1.0,
        1.0,  -1.0, 1.0,  0.0, 0.5, 1.0, 1.0,
        1.0,  -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,

        -1.0, 1.0,  -1.0, 1.0, 0.0, 0.5, 1.0,
        -1.0, 1.0,  1.0,  1.0, 0.0, 0.5, 1.0,
        1.0,  1.0,  1.0,  1.0, 0.0, 0.5, 1.0,
        1.0,  1.0,  -1.0, 1.0, 0.0, 0.5, 1.0,
    };

    const indices = [_]u16{
        0,  1,  2,  0,  2,  3,
        6,  5,  4,  7,  6,  4,
        8,  9,  10, 8,  10, 11,
        14, 13, 12, 15, 14, 12,
        16, 17, 18, 16, 18, 19,
        22, 21, 20, 23, 22, 20,
    };

    var buffer_desc = std.mem.zeroes(c.sg_buffer_desc);
    buffer_desc.size = vertices.len * @sizeOf(f32);
    buffer_desc.content = &vertices[0];
    state.main_bindings.vertex_buffers[0] = c.sg_make_buffer(&buffer_desc);

    buffer_desc = std.mem.zeroes(c.sg_buffer_desc);
    buffer_desc.type = .SG_BUFFERTYPE_INDEXBUFFER;
    buffer_desc.size = indices.len * @sizeOf(u16);
    buffer_desc.content = &indices[0];
    state.main_bindings.index_buffer = c.sg_make_buffer(&buffer_desc);

    const shader_desc = @ptrCast([*]const c.sg_shader_desc, glsl.cube_shader_desc());
    const shader = c.sg_make_shader(shader_desc);
    var pipeline_desc = std.mem.zeroes(c.sg_pipeline_desc);
    pipeline_desc.layout.attrs[0].format = .SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[1].format = .SG_VERTEXFORMAT_FLOAT4;
    pipeline_desc.layout.buffers[0].stride = 28;
    pipeline_desc.shader = shader;
    pipeline_desc.index_type = .SG_INDEXTYPE_UINT16;
    pipeline_desc.depth_stencil.depth_compare_func = .SG_COMPAREFUNC_LESS_EQUAL;
    pipeline_desc.depth_stencil.depth_write_enabled = true;
    pipeline_desc.rasterizer.cull_mode = .SG_CULLMODE_BACK;
    pipeline_desc.rasterizer.sample_count = SampleCount;
    state.main_pipeline = c.sg_make_pipeline(&pipeline_desc);
}

export fn update() void {
    const width = c.sapp_width();
    const height = c.sapp_height();
    const w: f32 = @intToFloat(f32, width);
    const h: f32 = @intToFloat(f32, height);
    const radians: f32 = 1.0472; //60 degrees
    var proj: Mat4 = Mat4.createPerspective(radians, w / h, 0.01, 100.0);
    var view: Mat4 = Mat4.createLookAt(Vec3.new(2.0, 3.5, 2.0), Vec3.new(0.0, 0.0, 0.0), Vec3.new(0.0, 1.0, 0.0));
    var view_proj = Mat4.mul(proj, view);
    rx += 1.0 / 220.0;
    ry += 2.0 / 220.0;
    var rxm = Mat4.createAngleAxis(Vec3.new(1, 0, 0),rx);
    var rym = Mat4.createAngleAxis(Vec3.new(0, 1, 0),ry);

    var model = Mat4.mul(rxm, rym);
    var mvp = Mat4.mul(view_proj, model);
    var vs_params = glsl.vs_params_t{
        .mvp = mvp.toArray(),
    };

    c.sg_begin_default_pass(&state.pass_action, width, height);
    c.sg_apply_pipeline(state.main_pipeline);
    c.sg_apply_bindings(&state.main_bindings);
    c.sg_apply_uniforms(.SG_SHADERSTAGE_VS, 0, &vs_params, @sizeOf(glsl.vs_params_t));
    c.sg_draw(0, 36, 1);
    c.sg_end_pass();
    c.sg_commit();
}

export fn cleanup() void {
    c.sg_shutdown();
}

pub fn main() void {
    var app_desc = std.mem.zeroes(c.sapp_desc);
    app_desc.width = 1280;
    app_desc.height = 720;
    app_desc.init_cb = init;
    app_desc.frame_cb = update;
    app_desc.cleanup_cb = cleanup;
    app_desc.sample_count = SampleCount;
    app_desc.window_title = "Cube (sokol-zig)";
    _ = c.sapp_run(&app_desc);
}
