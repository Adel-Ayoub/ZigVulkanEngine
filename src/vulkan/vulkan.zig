const std = @import("std");
const bk = @import("backend.zig");

pub const c = @cImport({
    @cInclude("vulkan/vulkan.h");
});

pub const Context = struct {
    const Self = @This();
    
    instance: c.VkInstance,

    pub fn init() !Self {
        std.log.info("Initializing Vulkan context...", .{});
        const instance = try bk.createInstance();
        std.log.info("Vulkan instance created successfully", .{});
        return Self{
            .instance = instance,
        };
    }

    pub fn deinit(self: Self) void {
        std.log.info("Destroying Vulkan instance...", .{});
        c.vkDestroyInstance(self.instance, null);
    }
};
