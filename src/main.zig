const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl3");
//const gfx = @import("gfx.zig");
const gfx = @import("vulkan_gfx.zig");
const nz = @import("numz");
const obj = @import("obj.zig");
const ecs = @import("ecs.zig");

const cube_positions = [_]nz.Vec3(f32){
    .{ 0.0, 10.0, 0.0 },
    .{ 100.0, 50.0, -50.0 },
    .{ -150.0, 120.0, -130.0 },
    .{ -80.0, -20.0, -90.0 },
    .{ 200.0, -10.0, -30.0 },
    .{ -250.0, 15.0, -70.0 },
    .{ 90.0, 80.0, -200.0 },
    .{ 160.0, 95.0, -140.0 },
    .{ 10.0, 5.0, -20.0 },
    .{ -170.0, 10.0, -25.0 },
};

pub fn Transform(T: type) type {
    return struct {
        position: nz.Vec3(T) = @splat(0),
        rotation: nz.Vec3(T) = @splat(0),
        scale: nz.Vec3(T) = @splat(1),
    };
}

pub const Renderable = struct {
    pipeline: *const gfx.Pipeline,
    texture: ?gfx.Texture = null,
    object: *const gfx.Object,
};

pub const RandomRotate = struct {
    speed: f32 = 50,
};

pub const FreeCamera = struct {
    speed: f32 = 50,
    sensitivity: f32 = 0.1,
    was_rotating: bool = false,
};

pub const World = ecs.World(&[_]type{ Transform(f32), Renderable, RandomRotate, FreeCamera });

pub fn main() !void {
    try sdl.init.init(.{ .video = true });
    defer sdl.init.shutdown();

    //try sdl.video.gl.setAttribute(.context_major_version, 4);
    // try sdl.video.gl.setAttribute(.context_minor_version, 6);
    //try sdl.video.gl.setAttribute(.context_profile_mask, @intFromEnum(sdl.video.gl.Profile.core));

    //try sdl.video.gl.setAttribute(.context_major_version, 2);
    //try sdl.video.gl.setAttribute(.context_minor_version, 1);

    const window = try sdl.video.Window.init("Vulkan zig engine", 900, 800, .{
        .resizable = true,
        //.open_gl = true,
    });
    defer window.deinit();

    const context = try gfx.Context.init(window);
    defer context.deinit();

    const allocator = std.heap.page_allocator;

    const bush_texture = try gfx.Texture.init("./assets/textures/bush.jpg");
    defer bush_texture.deinit();

    const grass_texture = try gfx.Texture.init("./assets/textures/grass_diff.jpg");
    defer grass_texture.deinit();
    const cube_texture = try gfx.Texture.init("./assets/textures/basket_diff.jpg");
    defer cube_texture.deinit();

    const bush_data = try obj.Obj.init(allocator, "./assets/models/xyzdragon.obj");
    defer bush_data.deinit();
    const bush = try gfx.Object.init(bush_data.vertices, bush_data.indices);
    defer bush.deinit();

    const cube_data = try obj.Obj.init(allocator, "./assets/models/basket.obj");
    defer cube_data.deinit();
    const cube = try gfx.Object.init(cube_data.vertices, cube_data.indices);
    defer cube.deinit();

    const plane_data = try obj.Obj.init(allocator, "./assets/models/quad.obj");
    defer plane_data.deinit();
    const plane = try gfx.Object.init(plane_data.vertices, plane_data.indices);
    defer plane.deinit();

    const default_pipeline = try gfx.Pipeline.init(
        @embedFile("./shaders/default.vert"),
        @embedFile("./shaders/default.frag"),
        null,
    );
    defer default_pipeline.deinit();

    var world = try World.init(allocator);
    defer world.deinit();

    for (0..cube_positions.len) |i| {
        _ = try world.spawn(.{
            Transform(f32){
                .position = cube_positions[i],
                .rotation = @splat(@floatFromInt(20 * i)),
                .scale = @splat(5),
            },
            Renderable{
                .pipeline = &default_pipeline,
                .texture = cube_texture,
                .object = &cube,
            },
            RandomRotate{
                .speed = @floatFromInt(10 * i),
            },
        });
    }

    var seed: u32 = 123456789;

    for (0..4) |i| {
        seed = seed ^ (1103515245 *% @as(u32, @intCast(i)) +% 12345);

        const rand_x = @as(f32, @floatFromInt(seed & 0x7FFFFFFF)) / 2147483648.0;

        seed = seed ^ (1103515245 *% (@as(u32, @intCast(i)) +% 999) +% 54321);
        const rand_z = @as(f32, @floatFromInt(seed & 0x7FFFFFFF)) / 2147483648.0;

        const x = rand_x * 1000.0 - 500.0;
        const z = rand_z * 1000.0 - 500.0;

        _ = try world.spawn(.{
            Transform(f32){
                .position = .{ x, x / z + @as(f32, @floatFromInt(i)), z },
                .rotation = .{ 0, @floatFromInt(20 * i), 0 },
                .scale = @splat(0.1),
            },
            Renderable{
                .pipeline = &default_pipeline,
                .texture = bush_texture,
                .object = &bush,
            },
            RandomRotate{
                .speed = @floatFromInt(10 * i),
            },
        });
    }

    _ = try world.spawn(.{
        Transform(f32){
            .position = .{ 0, -10, 0 },
            .rotation = .{ 90, 0, 0 },
            .scale = @splat(5000),
        },
        Renderable{
            .pipeline = &default_pipeline,
            .texture = grass_texture,
            .object = &plane,
        },
    });

    _ = try world.spawn(.{
        Transform(f32){
            .position = .{ 0, -10, 0 },
            .rotation = .{ 90, 0, 0 },
            .scale = @splat(5000),
        },
        FreeCamera{
            .sensitivity = 0.1,
        },
    });

    main: while (true) {
        while (sdl.events.poll()) |event| {
            switch (event) {
                .quit, .terminating => break :main,
                else => {},
            }
        }

        const delta_time = getDeltaTime();

        const fps = 1.0 / delta_time;
        std.debug.print("FPS: {d}\n", .{fps});

        // const time = @as(f32, @floatFromInt(sdl.c.SDL_GetTicks())) / 1000;

        const size = try window.getSize();
        const aspect = @as(f32, @floatFromInt(size.width)) / @as(f32, @floatFromInt(size.height));

        try context.clear();
        default_pipeline.bind();

        try freeCameraSystem(&world, delta_time, default_pipeline, aspect);
        try rotateSystem(&world, delta_time);
        try renderSystem(&world);

        try context.present();
    }
}

pub fn renderSystem(world: *World) !void {
    var it = world.query(&[_]type{ Transform(f32), Renderable });
    while (it.next()) |item| {
        const transform = item.get(Transform(f32));
        const renderable = item.get(Renderable);

        var model = nz.Mat4(f32).identity(1);

        model = model.mul(nz.Mat4(f32).translate(transform.position));
        if (transform.rotation[2] != 0) model = model.mul(nz.Mat4(f32).rotate(std.math.degreesToRadians(transform.rotation[2]), .{ 0, 0, 1 }));
        if (transform.rotation[1] != 0) model = model.mul(nz.Mat4(f32).rotate(std.math.degreesToRadians(transform.rotation[1]), .{ 0, 1, 0 }));
        if (transform.rotation[0] != 0) model = model.mul(nz.Mat4(f32).rotate(std.math.degreesToRadians(transform.rotation[0]), .{ 1, 0, 0 }));
        if (!nz.eql(transform.scale, @as(nz.Vec3(f32), @splat(1)))) model = model.mul(nz.Mat4(f32).scale(transform.scale));

        if (renderable.texture != null) renderable.texture.?.bind(0);

        try renderable.pipeline.setUniform("u_model", .{ .mat4 = .{ model.d, false } });
        renderable.object.draw();
    }
}

pub fn rotateSystem(world: *World, delta_time: f32) !void {
    var it = world.query(&[_]type{ Transform(f32), RandomRotate });
    while (it.next()) |item| {
        const transform = item.get(Transform(f32));
        const random_rotate = item.get(RandomRotate);

        inline for (0..3) |i| {
            transform.rotation[i] += delta_time * random_rotate.speed;
            transform.rotation[i] = @mod(transform.rotation[i], 360);
        }
    }
}

pub fn freeCameraSystem(world: *World, delta_time: f32, pipeline: gfx.Pipeline, aspect: f32) !void {
    var it = world.query(&[_]type{ Transform(f32), FreeCamera });
    while (it.next()) |item| {
        const transform = item.get(Transform(f32));
        const camera = item.get(FreeCamera);

        const pitch = &transform.rotation[0];
        const yaw = &transform.rotation[1];

        const mouse = sdl.mouse.getState();

        const relative = sdl.mouse.getRelativeState();

        if (mouse.flags.right) {
            try sdl.mouse.hide();

            yaw.* += relative.x * camera.sensitivity;
            pitch.* += relative.y * camera.sensitivity;
            camera.was_rotating = true;
        } else if (camera.was_rotating) {
            _ = sdl.mouse.getRelativeState();
            camera.was_rotating = false;
            try sdl.mouse.show();
        }

        pitch.* = std.math.clamp(pitch.*, -89.9, 89.9);

        const keyboard = sdl.keyboard.getState();

        const yaw_rad = std.math.degreesToRadians(yaw.*);
        const pitch_rad = std.math.degreesToRadians(pitch.*);

        const forward = nz.normalize(nz.Vec3(f32){
            @cos(pitch_rad) * @sin(yaw_rad),
            -@sin(pitch_rad),
            -@cos(pitch_rad) * @cos(yaw_rad),
        });

        const right = nz.normalize(nz.cross(forward, nz.Vec3(f32){ 0, 1, 0 }));

        const up = nz.normalize(nz.cross(right, forward));

        var move = nz.Vec3(f32){ 0, 0, 0 };
        const velocity = camera.speed * delta_time;

        if (keyboard[@intFromEnum(sdl.Scancode.w)])
            move -= nz.scale(forward, velocity);
        if (keyboard[@intFromEnum(sdl.Scancode.s)])
            move += nz.scale(forward, velocity);
        if (keyboard[@intFromEnum(sdl.Scancode.a)])
            move += nz.scale(right, velocity);
        if (keyboard[@intFromEnum(sdl.Scancode.d)])
            move -= nz.scale(right, velocity);
        if (keyboard[@intFromEnum(sdl.Scancode.space)])
            move -= nz.scale(up, velocity);
        if (keyboard[@intFromEnum(sdl.Scancode.left_ctrl)])
            move += nz.scale(up, velocity);

        if (keyboard[@intFromEnum(sdl.Scancode.up)])
            camera.speed += 10;
        if (keyboard[@intFromEnum(sdl.Scancode.down)])
            camera.speed -= 10;

        const speed_multiplier: f32 = @floatFromInt(@intFromBool(keyboard[@intFromEnum(sdl.Scancode.left_shift)]));

        camera.speed = std.math.clamp(camera.speed, 0, 1000);

        transform.position += nz.scale(move, speed_multiplier + 1);

        if (keyboard[@intFromEnum(sdl.Scancode.r)]) {
            yaw.* = 0;
            pitch.* = 0;
            transform.position = .{ 0, 0, 0 };
        }

        var view = nz.Mat4(f32).identity(1);
        view = view.mul(nz.Mat4(f32).rotate(std.math.degreesToRadians(pitch.*), .{ 1, 0, 0 }));
        view = view.mul(nz.Mat4(f32).rotate(std.math.degreesToRadians(yaw.*), .{ 0, 1, 0 }));
        view = view.mul(nz.Mat4(f32).translate(transform.position));

        const projection = nz.Mat4(f32).perspective(std.math.degreesToRadians(45.0), aspect, 4, 4000.0);

        try pipeline.setUniform("u_projection", .{ .mat4 = .{ projection.d, false } });
        try pipeline.setUniform("u_view", .{ .mat4 = .{ view.d, false } });
    }
}

var last_time: u64 = 0;

pub fn getDeltaTime() f32 {
    const now = sdl.c.SDL_GetPerformanceCounter();
    const freq = sdl.c.SDL_GetPerformanceFrequency();
    const delta_time = @as(f32, @floatFromInt(now - last_time)) / @as(f32, @floatFromInt(freq));
    last_time = now;
    return delta_time;
}
