# ZigVulkanEngine
## A 3D game engine built with Zig and Vulkan

> **Work in Progress** - This project is currently under active development.

## How to Install ZigVulkanEngine

### From Source
```bash
git clone https://github.com/Adel-Ayoub/ZigVulkanEngine.git
cd ZigVulkanEngine
zig build run
```

## Controls

| Action | Key |
| ------ | --- |
| **Move Camera** | WASD |
| **Look Around** | Right Mouse + Drag |
| **Reset Camera** | R |
| **Speed Boost** | Shift |
| **Exit** | Close Window |

## Features

| Feature | Implementation |
| ------- | -------------- |
| **Vulkan Rendering** | MoltenVK support for cross-platform graphics |
| **Entity Component System** | Efficient game object management |
| **Asset Loading** | 3D models and 4K texture support |
| **Camera System** | Free-look camera with smooth controls |
| **Shader System** | GLSL vertex and fragment shaders with lighting |

## Technical Stack

- **Zig** - Systems programming language
- **Vulkan** - Low-level graphics API
- **MoltenVK** - Vulkan-to-Metal translation layer
- **SDL3** - Cross-platform windowing and input

## Requirements

- Zig 0.15.0-dev or later
- Vulkan SDK
- SDL3 and SDL3_image
- MoltenVK (for macOS)

## Known Issues

> Rendering is currently stubbed - graphics framework is functional but visual output is not yet implemented.
