const std = @import("std");
const c = @import("c.zig");
const Mat4 = @import("math3d.zig").Mat4;
const Vec3 = @import("math3d.zig").Vec3;
const glsl = @cImport({
    @cInclude("sokol/sokol_gfx.h");
    @cInclude("shaders/instancing.glsl.h");
});
const rand = @import("std").rand;

const SampleCount = 4;
const NumParticlesEmittedPerFrame = 10;
const MaxParticles: u32 = 512 * 2014;

const State = struct {
    pass_action: c.sg_pass_action,
    main_pipeline: c.sg_pipeline,
    main_bindings: c.sg_bindings,
};
var rndgen = rand.DefaultPrng.init(42);
var ry: f32 = 0.0;
var state: State = undefined;
var cur_num_particles: u32 = 0;
var pos: [MaxParticles]Vec3 = undefined;
var vel: [MaxParticles]Vec3 = undefined;

fn frnd(range: f32) f32 {
    return rndgen.random().float(f32) * range;
}

export fn init() void {
    var desc = std.mem.zeroes(c.sg_desc);
    desc.context = c.sapp_sgcontext();
    c.sg_setup(&desc);
    c.stm_setup();

    state.pass_action.colors[0].action = c.SG_ACTION_CLEAR;
    state.pass_action.colors[0].value = c.sg_color{ .r = 0.2, .g = 0.2, .b = 0.2, .a = 1.0 };
    const r = 0.05;
    const vertices = [_]f32{
        // positions            colors
        0.0, -r,  0.0, 1.0, 0.0, 0.0, 1.0,
        r,   0.0, r,   0.0, 1.0, 0.0, 1.0,
        r,   0.0, -r,  0.0, 0.0, 1.0, 1.0,
        -r,  0.0, -r,  1.0, 1.0, 0.0, 1.0,
        -r,  0.0, r,   0.0, 1.0, 1.0, 1.0,
        0.0, r,   0.0, 1.0, 0.0, 1.0, 1.0,
    };

    const indices = [_]u16{
        0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1,
        5, 1, 2, 5, 2, 3, 5, 3, 4, 5, 4, 1,
    };

    var vertex_buffer_desc = std.mem.zeroes(c.sg_buffer_desc);
    vertex_buffer_desc.size = vertices.len * @sizeOf(f32);
    vertex_buffer_desc.data = .{ .ptr = &vertices[0], .size = vertex_buffer_desc.size };
    state.main_bindings.vertex_buffers[0] = c.sg_make_buffer(&vertex_buffer_desc);

    var index_buffer_desc = std.mem.zeroes(c.sg_buffer_desc);
    index_buffer_desc.type = c.SG_BUFFERTYPE_INDEXBUFFER;
    index_buffer_desc.size = indices.len * @sizeOf(u16);
    index_buffer_desc.data = .{ .ptr = &indices[0], .size = index_buffer_desc.size };
    state.main_bindings.index_buffer = c.sg_make_buffer(&index_buffer_desc);

    var instance_buffer_desc = std.mem.zeroes(c.sg_buffer_desc);
    instance_buffer_desc.size = MaxParticles * @sizeOf(Vec3);
    instance_buffer_desc.usage = c.SG_USAGE_STREAM;
    state.main_bindings.vertex_buffers[1] = c.sg_make_buffer(&instance_buffer_desc);

    const shader_desc = @ptrCast([*]const c.sg_shader_desc, glsl.instancing_shader_desc(glsl.sg_query_backend()));
    const shader = c.sg_make_shader(shader_desc);

    var pipeline_desc = std.mem.zeroes(c.sg_pipeline_desc);
    pipeline_desc.layout.attrs[glsl.ATTR_vs_pos].format = c.SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[glsl.ATTR_vs_color0].format = c.SG_VERTEXFORMAT_FLOAT4;
    pipeline_desc.layout.attrs[glsl.ATTR_vs_inst_pos].format = c.SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[glsl.ATTR_vs_inst_pos].buffer_index = 1;
    pipeline_desc.layout.buffers[1].step_func = c.SG_VERTEXSTEP_PER_INSTANCE;
    pipeline_desc.shader = shader;
    pipeline_desc.index_type = c.SG_INDEXTYPE_UINT16;
    pipeline_desc.depth.compare = c.SG_COMPAREFUNC_LESS_EQUAL;
    pipeline_desc.depth.write_enabled = true;
    pipeline_desc.cull_mode = c.SG_CULLMODE_BACK;
    state.main_pipeline = c.sg_make_pipeline(&pipeline_desc);
}

export fn update() void {
    const width = c.sapp_width();
    const height = c.sapp_height();
    const w: f32 = @floatFromInt(f32, width);
    const h: f32 = @floatFromInt(f32, height);
    const radians: f32 = 1.0472; //60 degrees
    const frame_time = 1.0 / 60.0;

    // See git history for what this code *should* look like. This was modified to take a reference
    // of the arrays to avoid copies to the stack on due to Zig compiler issues on 0.11.0-dev.3771+128fd7dd0
    // Without taking a reference this will stack overflow.

    // emit new particles
    var i: u32 = 0;
    while (i < NumParticlesEmittedPerFrame) : (i += 1) {
        if (cur_num_particles < MaxParticles) {
            (&pos)[cur_num_particles] = Vec3.new(0, 0, 0);
            (&vel)[cur_num_particles] = Vec3.new(frnd(1) - 0.5, frnd(1) * 0.5 + 2.0, frnd(1) - 0.5);
            cur_num_particles += 1;
        } else {
            break;
        }
    }
    i = 0;
    // update particle positions
    while (i < cur_num_particles) : (i += 1) {
        (&vel)[i].y -= 1.0 * frame_time;
        (&pos)[i].x += (&vel)[i].x * frame_time;
        (&pos)[i].y += (&vel)[i].y * frame_time;
        (&pos)[i].z += (&vel)[i].z * frame_time;
        // bounce back from 'ground'
        if ((&pos)[i].y < -2.0) {
            (&pos)[i].y = -1.8;
            (&vel)[i].y = -(&vel)[i].y;
            (&vel)[i].x *= 0.8;
            (&vel)[i].y *= 0.8;
            (&vel)[i].z *= 0.8;
        }
    }

    // update instance data
    c.sg_update_buffer(state.main_bindings.vertex_buffers[1], &c.sg_range{
        .ptr = &pos[0],
        .size = cur_num_particles * @sizeOf(Vec3),
    });

    var proj: Mat4 = Mat4.createPerspective(radians, w / h, 0.01, 100.0);
    var view: Mat4 = Mat4.createLookAt(Vec3.new(0.0, 1.5, 12.0), Vec3.new(0.0, 0.0, 0.0), Vec3.new(0.0, 1.0, 0.0));
    var view_proj = Mat4.mul(proj, view);
    ry += 2.0 / 400.0;
    var vs_params = glsl.vs_params_t{
        .mvp = Mat4.mul(view_proj, Mat4.createAngleAxis(Vec3.new(0, 1, 0), ry)).toArray(),
    };

    c.sg_begin_default_pass(&state.pass_action, width, height);
    c.sg_apply_pipeline(state.main_pipeline);
    c.sg_apply_bindings(&state.main_bindings);
    c.sg_apply_uniforms(c.SG_SHADERSTAGE_VS, glsl.SLOT_vs_params, &c.sg_range{ .ptr = &vs_params, .size = @sizeOf(glsl.vs_params_t) });
    c.sg_draw(0, 24, @intCast(c_int, cur_num_particles));
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
    app_desc.window_title = "Instancing (sokol-zig)";
    _ = c.sapp_run(&app_desc);
}
