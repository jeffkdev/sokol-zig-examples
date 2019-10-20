const std = @import("std");
const c = @import("c.zig");
const Mat4 = @import("math3d.zig").Mat4;
const Vec3 = @import("math3d.zig").Vec3;
const m = @import("math3d.zig");
const glsl = @cImport({
    @cInclude("sokol/sokol_gfx.h");
    @cInclude("shaders/instancing.glsl.h");
});
const rand = @import("std").rand;

fn zero_struct(comptime T: type) T {
    var variable: T = undefined;
    @memset(@ptrCast([*]u8, &variable), 0, @sizeOf(T));
    return variable;
}

const SampleCount = 4;
const NumParticlesEmittedPerFrame = 10;
const MaxParticles: u32 = 512 * 2014;

const State = struct {
    pass_action: c.sg_pass_action,
    main_pipeline: c.sg_pipeline,
    main_bindings: c.sg_bindings,
};

var ry: f32 = 0.0;
var state: State = undefined;
var cur_num_particles: u32 = 0;
var pos: [MaxParticles]Vec3 = undefined;
var vel: [MaxParticles]Vec3 = undefined;

export fn init() void {
    var desc = zero_struct(c.sg_desc);
    c.sg_setup(&desc);
    c.stm_setup();

    state.pass_action.colors[0].action = c.SG_ACTION_CLEAR;
    state.pass_action.colors[0].val = [_]f32{ 0.2, 0.2, 0.2, 1.0 };
    const r = 0.05;
    const vertices = [_]f32 {
        // positions            colors
        0.0,   -r, 0.0,       1.0, 0.0, 0.0, 1.0,
           r, 0.0, r,          0.0, 1.0, 0.0, 1.0,
           r, 0.0, -r,         0.0, 0.0, 1.0, 1.0,
          -r, 0.0, -r,         1.0, 1.0, 0.0, 1.0,
          -r, 0.0, r,          0.0, 1.0, 1.0, 1.0,
        0.0,    r, 0.0,       1.0, 0.0, 1.0, 1.0
    };

    const indices = [_]u16{
        0, 1, 2,    0, 2, 3,    0, 3, 4,    0, 4, 1,
        5, 1, 2,    5, 2, 3,    5, 3, 4,    5, 4, 1
    };

    var vertex_buffer_desc = zero_struct(c.sg_buffer_desc);
    vertex_buffer_desc.size = vertices.len * @sizeOf(f32);
    vertex_buffer_desc.content = &vertices[0];
    state.main_bindings.vertex_buffers[0] = c.sg_make_buffer(&vertex_buffer_desc);
    //-
    var index_buffer_desc = zero_struct(c.sg_buffer_desc);
    index_buffer_desc.type = c.SG_BUFFERTYPE_INDEXBUFFER;
    index_buffer_desc.size = indices.len * @sizeOf(u16);
    index_buffer_desc.content = &indices[0];
    state.main_bindings.index_buffer = c.sg_make_buffer(&index_buffer_desc);
    //-
    var instance_buffer_desc = zero_struct(c.sg_buffer_desc);
    instance_buffer_desc.size = MaxParticles * @sizeOf(Vec3);
    instance_buffer_desc.usage = c.SG_USAGE_STREAM;
    state.main_bindings.vertex_buffers[1] = c.sg_make_buffer(&instance_buffer_desc);
    //-
    const shader_desc = @ptrCast([*c]const c.sg_shader_desc, glsl.instancing_shader_desc());
    const shader = c.sg_make_shader(shader_desc);
    //-
    var pipeline_desc = zero_struct(c.sg_pipeline_desc);
    pipeline_desc.layout.attrs[glsl.ATTR_vs_pos].format = c.SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[glsl.ATTR_vs_color0].format = c.SG_VERTEXFORMAT_FLOAT4;
    pipeline_desc.layout.attrs[glsl.ATTR_vs_inst_pos].format = c.SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[glsl.ATTR_vs_inst_pos].buffer_index = 1;
    pipeline_desc.layout.buffers[1].step_func = c.SG_VERTEXSTEP_PER_INSTANCE;
    pipeline_desc.shader = shader;
    pipeline_desc.index_type = c.SG_INDEXTYPE_UINT16;
    pipeline_desc.depth_stencil.depth_compare_func = c.SG_COMPAREFUNC_LESS_EQUAL;
    pipeline_desc.depth_stencil.depth_write_enabled = true;
    pipeline_desc.rasterizer.cull_mode = c.SG_CULLMODE_BACK;
    pipeline_desc.rasterizer.sample_count = SampleCount;
    state.main_pipeline = c.sg_make_pipeline(&pipeline_desc);
}

var rndgen = rand.DefaultPrng.init(42);

fn frnd(range: f32) f32 {
    return rndgen.random.float(f32) * range;
}

export fn update() void {
    const width = c.sapp_width();
    const height = c.sapp_height();
    const w: f32 = @intToFloat(f32, width);
    const h: f32 = @intToFloat(f32, height);
    const radians: f32 = 1.0472; //60 degrees
    const frame_time = 1.0 / 60.0;

    //e mit new particles
    var i: u32 = 0;
    while (i < NumParticlesEmittedPerFrame) : (i += 1) {
        if (cur_num_particles < MaxParticles) {
            pos[cur_num_particles] = m.vec3(0, 0, 0);
            vel[cur_num_particles] = m.vec3(frnd(1) - 0.5, frnd(1) * 0.5 + 2.0, frnd(1) - 0.5);
            cur_num_particles += 1;
        } else {
            break;
        }
    }
    i = 0;
    // update particle positions
    while (i < cur_num_particles) : (i += 1) {
        vel[i].y -= 1.0 * frame_time;
        pos[i].x += vel[i].x * frame_time;
        pos[i].y += vel[i].y * frame_time;
        pos[i].z += vel[i].z * frame_time;
        // bounce back from 'ground'
        if (pos[i].y < -2.0) {
            pos[i].y = -1.8;
            vel[i].y = -vel[i].y;
            vel[i].x *= 0.8;
            vel[i].y *= 0.8;
            vel[i].z *= 0.8;
        }
    }

    // update instance data
    c.sg_update_buffer(state.main_bindings.vertex_buffers[1], &pos[0], @intCast(c_int, cur_num_particles * @sizeOf(Vec3)));

    var proj: Mat4 = Mat4.createPerspective(radians, w / h, 0.01, 100.0);
    var view: Mat4 = Mat4.createLookAt(m.vec3(0.0, 1.5, 12.0), m.vec3(0.0, 0.0, 0.0), m.vec3(0.0, 1.0, 0.0));
    var view_proj = Mat4.mul(view, proj);
    ry += 2.0 / 400.0;
    var vs_params = glsl.vs_params_t{
        .mvp = Mat4.mul(Mat4.createAngleAxis(m.vec3(0, 1, 0), ry),view_proj).toArray(),
    };

    c.sg_begin_default_pass(&state.pass_action, width, height);
    c.sg_apply_pipeline(state.main_pipeline);
    c.sg_apply_bindings(&state.main_bindings);
    c.sg_apply_uniforms(c.SG_SHADERSTAGE_VS, glsl.SLOT_vs_params, &vs_params, @sizeOf(glsl.vs_params_t));
    c.sg_draw(0, 24, @intCast(c_int, cur_num_particles));
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
    app_desc.sample_count = SampleCount;
    app_desc.window_title = c"Instancing (sokol-zig)";
    return app_desc;
}
