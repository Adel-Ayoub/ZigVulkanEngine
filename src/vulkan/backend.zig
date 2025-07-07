const std = @import("std");
const c = @import("vulkan.zig").c;

pub fn createInstance() !c.VkInstance {
    const app_info = c.VkApplicationInfo{
        .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pNext = null,
        .pApplicationName = "Game Engine Test",
        .applicationVersion = c.VK_MAKE_VERSION(1, 0, 0),
        .pEngineName = "Test Engine",
        .engineVersion = c.VK_MAKE_VERSION(1, 0, 0),
        .apiVersion = c.VK_API_VERSION_1_0,
    };

    // Required extensions for MoltenVK on macOS
    const extension_names = [_][*:0]const u8{
        "VK_KHR_surface",
        "VK_EXT_metal_surface",
        "VK_KHR_portability_enumeration",
    };

    const create_info = c.VkInstanceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pNext = null,
        .flags = c.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
        .pApplicationInfo = &app_info,
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = extension_names.len,
        .ppEnabledExtensionNames = &extension_names[0],
    };

    var instance: c.VkInstance = undefined;
    const result = c.vkCreateInstance(&create_info, null, &instance);
    
    if (result != c.VK_SUCCESS) {
        std.log.err("Vulkan instance creation failed with result: {} (VK_ERROR_EXTENSION_NOT_PRESENT = -7)", .{result});
        
        // Try minimal instance creation as fallback
        std.log.info("Trying minimal Vulkan instance creation...", .{});
        const minimal_info = c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .pApplicationInfo = &app_info,
            .enabledLayerCount = 0,
            .ppEnabledLayerNames = null,
            .enabledExtensionCount = 0,
            .ppEnabledExtensionNames = null,
        };
        
        const minimal_result = c.vkCreateInstance(&minimal_info, null, &instance);
        if (minimal_result != c.VK_SUCCESS) {
            std.log.err("Even minimal Vulkan instance creation failed: {}", .{minimal_result});
            return error.VulkanInstanceCreationFailed;
        }
        std.log.info("Minimal Vulkan instance created successfully", .{});
    } else {
        std.log.info("Full Vulkan instance with extensions created successfully", .{});
    }
    
    return instance;
}
