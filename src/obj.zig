const std = @import("std");
const mem = @import("std").mem;
const fmt = @import("std").fmt;

pub const Obj = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    vertices: []f32,
    indices: []u32,

    pub fn init(
        allocator: std.mem.Allocator,
        path: []const u8,
    ) !Self {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const tok_buffer = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
        var lines = mem.tokenizeAny(u8, tok_buffer, "\n");

        var positions = std.ArrayList(f32).init(allocator);
        defer positions.deinit();
        var uvs = std.ArrayList(f32).init(allocator);
        defer uvs.deinit();
        var normals = std.ArrayList(f32).init(allocator);
        defer normals.deinit();

        var vertices = std.ArrayList(f32).init(allocator);
        var indices = std.ArrayList(u32).init(allocator);

        var vertex_count: u32 = 0;

        while (lines.next()) |line| {
            if (line.len == 0) continue;

            switch (line[0]) {
                'v' => {
                    if (line.len < 2) continue;

                    var array: *std.ArrayList(f32) = switch (line[1]) {
                        ' ' => &positions,
                        't' => &uvs,
                        'n' => &normals,
                        else => continue,
                    };

                    var parts = mem.splitAny(u8, line[2..], " ");
                    while (parts.next()) |part| {
                        const trimmed = mem.trim(u8, part, "\n\r\t ");
                        if (trimmed.len == 0) continue;
                        try array.append(try fmt.parseFloat(f32, trimmed));
                    }
                },

                'f' => {
                    var face_vertices = std.ArrayList(u32).init(allocator);
                    defer face_vertices.deinit();

                    var faces = mem.splitAny(u8, line[2..], " ");
                    while (faces.next()) |face| {
                        if (face.len == 0) continue;

                        var it = mem.splitAny(u8, face, "/");

                        const position_idx = try fmt.parseInt(usize, mem.trim(u8, it.next().?, " \n\r\t"), 10) - 1;
                        if (position_idx * 3 + 2 >= positions.items.len) return error.InvalidIndex;

                        try vertices.appendSlice(&[3]f32{
                            positions.items[position_idx * 3 + 0],
                            positions.items[position_idx * 3 + 1],
                            positions.items[position_idx * 3 + 2],
                        });

                        if (it.next()) |uv| {
                            const trimmed_uv = mem.trim(u8, uv, " \n\r\t");
                            if (trimmed_uv.len > 0) {
                                const uv_idx = try fmt.parseInt(usize, trimmed_uv, 10) - 1;
                                if (uv_idx * 2 + 1 >= uvs.items.len) return error.InvalidIndex;

                                try vertices.appendSlice(&[2]f32{
                                    uvs.items[uv_idx * 2 + 0],
                                    uvs.items[uv_idx * 2 + 1],
                                });
                            } else try vertices.appendSlice(&[_]f32{ 0, 0 });
                        } else try vertices.appendSlice(&[_]f32{ 0, 0 });

                        if (it.next()) |normal| {
                            const normal_idx = try fmt.parseInt(usize, mem.trim(u8, normal, " \n\r\t"), 10) - 1;
                            if (normal_idx * 3 + 2 >= normals.items.len) return error.InvalidIndex;

                            try vertices.appendSlice(&[3]f32{
                                normals.items[normal_idx * 3 + 0],
                                normals.items[normal_idx * 3 + 1],
                                normals.items[normal_idx * 3 + 2],
                            });
                        } else try vertices.appendSlice(&[_]f32{ 0, 1, 0 });

                        try face_vertices.append(vertex_count);
                        vertex_count += 1;
                    }

                    if (face_vertices.items.len >= 3) {
                        for (1..face_vertices.items.len - 1) |i| {
                            try indices.appendSlice(&[_]u32{
                                face_vertices.items[0],
                                face_vertices.items[i],
                                face_vertices.items[i + 1],
                            });
                        }
                    }
                },

                else => {},
            }
        }

        return .{
            .allocator = allocator,
            .vertices = try vertices.toOwnedSlice(),
            .indices = try indices.toOwnedSlice(),
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.indices);
        self.allocator.free(self.vertices);
    }
};
