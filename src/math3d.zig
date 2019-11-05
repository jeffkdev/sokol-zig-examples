// Copyright (c) 2019 Felix Queißner
// This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
// 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

// Altered source. Added: toArray. Altered: lookAt, perspective. Made column major. Removed Vec2/Vec4. Only kept necessary methods for examples. removed tests

const std = @import("std");

pub const Vec3 = extern struct {
    const Self = @This();
    pub x: f32,
    pub y: f32,
    pub z: f32,

    pub fn length2(a: Self) f32 {
        return Self.dot(a, a);
    }
    pub fn length(a: Self) f32 {
        return std.math.sqrt(a.length2());
    }
    pub fn dot(a: Self, b: Self) f32 {
        var result: f32 = 0;
        inline for (@typeInfo(Self).Struct.fields) |fld| {
            result += @field(a, fld.name) * @field(b, fld.name);
        }
        return result;
    }
    pub fn new(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{
            .x = x,
            .y = y,
            .z = z,
        };
    }
    pub fn scale(a: Self, b: f32) Self {
        var result: Self = undefined;
        inline for (@typeInfo(Self).Struct.fields) |fld| {
            @field(result, fld.name) = @field(a, fld.name) * b;
        }
        return result;
    }

    pub fn cross(a: Self, b: Self) Self {
        return Self{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }

    pub fn normalize(vec: Self) Self {
        return vec.scale(1.0 / vec.length());
    }

    pub fn sub(a: Self, b: Self) Self {
        var result: Self = undefined;
        inline for (@typeInfo(Self).Struct.fields) |fld| {
            @field(result, fld.name) = @field(a, fld.name) - @field(b, fld.name);
        }
        return result;
    }
};
pub fn vec3(x: f32, y: f32, z: f32) Vec3 {
    return Vec3.new(x, y, z);
}

pub const Mat4 = extern struct {
    pub const Self = @This();
    fields: [4][4]f32, // [col][row]

    pub const zero = Self{
        .fields = [4][4]f32{
            [4]f32{ 0, 0, 0, 0 },
            [4]f32{ 0, 0, 0, 0 },
            [4]f32{ 0, 0, 0, 0 },
            [4]f32{ 0, 0, 0, 0 },
        },
    };

    pub const identity = Self{
        .fields = [4][4]f32{
            [4]f32{ 1, 0, 0, 0 },
            [4]f32{ 0, 1, 0, 0 },
            [4]f32{ 0, 0, 1, 0 },
            [4]f32{ 0, 0, 0, 1 },
        },
    };

    pub fn mul(a: Self, b: Self) Self {
        var result: Self = undefined;
        inline for ([_]comptime_int{ 0, 1, 2, 3 }) |col| {
            inline for ([_]comptime_int{ 0, 1, 2, 3 }) |row| {
                var sum: f32 = 0.0;
                inline for ([_]comptime_int{ 0, 1, 2, 3 }) |i| {
                    sum += a.fields[i][row] * b.fields[col][i];
                }
                result.fields[col][row] = sum;
            }
        }
        return result;
    }
    // taken from GLM implementation
    pub fn createLook(eye: Vec3, direction: Vec3, up: Vec3) Self {
        const f = direction.normalize();
        const s = Vec3.cross(up, f).normalize();
        const u = Vec3.cross(f, s);

        var result = Self.identity;
        result.fields[0][0] = s.x;
        result.fields[1][0] = s.y;
        result.fields[2][0] = s.z;
        result.fields[0][1] = u.x;
        result.fields[1][1] = u.y;
        result.fields[2][1] = u.z;
        result.fields[0][2] = f.x;
        result.fields[1][2] = f.y;
        result.fields[2][2] = f.z;
        result.fields[3][0] = -Vec3.dot(s, eye);
        result.fields[3][1] = -Vec3.dot(u, eye);
        result.fields[3][2] = -Vec3.dot(f, eye);
        return result;
    }

    pub fn createLookAt(eye: Vec3, center: Vec3, up: Vec3) Self {
        return createLook(eye, Vec3.sub(eye, center), up);
    }

    // taken from GLM implementation
    pub fn createPerspective(fov: f32, aspect: f32, near: f32, far: f32) Self {
        std.debug.assert(std.math.fabs(aspect - 0.001) > 0);
        std.debug.assert(far > near);
        const tanHalfFov = std.math.tan(fov / 2);

        var result = Self.zero;
        result.fields[0][0] = 1.0 / (aspect * tanHalfFov);
        result.fields[1][1] = 1.0 / (tanHalfFov);
        result.fields[2][2] = -(far + near) / (far - near);
        result.fields[2][3] = -1.0;
        result.fields[3][2] = -(2.0 * far * near) / (far - near);
        return result;
    }

    pub fn createAngleAxis(axis: Vec3, angle: f32) Self {
        var cos = std.math.cos(angle);
        var sin = std.math.sin(angle);
        var x = axis.x;
        var y = axis.y;
        var z = axis.z;

        return Self{
            .fields = [4][4]f32{
                [4]f32{ cos + x * x * (1 - cos), x * y * (1 - cos) - z * sin, x * z * (1 - cos) + y * sin, 0 },
                [4]f32{ y * x * (1 - cos) + z * sin, cos + y * y * (1 - cos), y * z * (1 - cos) - x * sin, 0 },
                [4]f32{ z * x * (1 * cos) - y * sin, z * y * (1 - cos) + x * sin, cos + z * z * (1 - cos), 0 },
                [4]f32{ 0, 0, 0, 1 },
            },
        };
    }

    pub fn createOrthogonal(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Self {
        var result = Self.identity;
        result.fields[0][0] = 2 / (right - left);
        result.fields[1][1] = 2 / (top - bottom);
        result.fields[2][2] = 1 / (far - near);
        result.fields[3][0] = -(right + left) / (right - left);
        result.fields[3][1] = -(top + bottom) / (top - bottom);
        result.fields[3][2] = -near / (far - near);
        return result;
    }

    pub fn toArray(m: Self) [16]f32 {
        var result: [16]f32 = undefined;
        result[0] = m.fields[0][0];
        result[1] = m.fields[0][1];
        result[2] = m.fields[0][2];
        result[3] = m.fields[0][3];

        result[4] = m.fields[1][0];
        result[5] = m.fields[1][1];
        result[6] = m.fields[1][2];
        result[7] = m.fields[1][3];

        result[8] = m.fields[2][0];
        result[9] = m.fields[2][1];
        result[10] = m.fields[2][2];
        result[11] = m.fields[2][3];

        result[12] = m.fields[3][0];
        result[13] = m.fields[3][1];
        result[14] = m.fields[3][2];
        result[15] = m.fields[3][3];
        return result;
    }
};
