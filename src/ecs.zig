const std = @import("std");

pub fn World(component_types: []const type) type {
    const fields: [component_types.len]std.builtin.Type.StructField = comptime blk: {
        var result: [component_types.len]std.builtin.Type.StructField = undefined;
        for (component_types, 0..) |T, i| {
            const Type = std.AutoHashMap(u32, T);
            result[i] = std.builtin.Type.StructField{
                .name = @typeName(T),
                .type = Type,
                .default_value_ptr = null,
                .alignment = @alignOf(Type),
                .is_comptime = false,
            };
        }
        break :blk result;
    };

    const ComponentLayout = @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .fields = &fields,
            .decls = &.{},
            .is_tuple = false,
        },
    });

    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        layout: ComponentLayout,

        next_id: u32 = 0,

        pub fn init(allocator: std.mem.Allocator) !Self {
            var comps: ComponentLayout = undefined;

            inline for (component_types) |T| {
                const field_name = @typeName(T);
                const field_ptr = &@field(comps, field_name);
                field_ptr.* = std.AutoHashMap(u32, T).init(allocator);
            }

            return Self{
                .allocator = allocator,
                .layout = comps,
            };
        }

        pub fn deinit(self: *Self) void {
            inline for (component_types) |T| {
                @field(self.layout, @typeName(T)).deinit();
            }
        }

        pub fn spawn(self: *Self, data: anytype) !u32 {
            const entity_id: u32 = self.next_id;
            self.next_id += 1;

            inline for (data) |entry| {
                const T = @TypeOf(entry);
                const map = &@field(self.layout, @typeName(T));
                try map.put(entity_id, entry);
            }

            return entity_id;
        }

        pub fn query(self: *Self, comptime SearchTypes: []const type) EntityIterator(component_types, SearchTypes) {
            return EntityIterator(component_types, SearchTypes).init(self);
        }
    };
}

pub fn EntityIterator(comptime ComponentTypes: []const type, comptime SearchTypes: []const type) type {
    return struct {
        const Self = @This();

        world: *World(ComponentTypes),
        iter: std.AutoHashMap(u32, SearchTypes[0]).Iterator,

        pub fn init(world: *World(ComponentTypes)) Self {
            return .{
                .world = world,
                .iter = @field(world.layout, @typeName(SearchTypes[0])).iterator(),
            };
        }

        pub fn next(self: *Self) ?Entry {
            blk: while (self.iter.next()) |entry| {
                const id = entry.key_ptr.*;

                var components: [SearchTypes.len]*anyopaque = undefined;
                inline for (SearchTypes, 0..) |T, i| {
                    const map = @as(std.AutoHashMap(u32, T), @field(self.world.layout, @typeName(T)));
                    const ptr = map.getPtr(id) orelse continue :blk;
                    components[i] = ptr;
                }

                return Entry{ .entity = id, .components = components };
            }
            return null;
        }

        pub const Entry = struct {
            entity: u32,
            components: [SearchTypes.len]*anyopaque,

            pub fn get(self: Entry, comptime T: type) *T {
                inline for (SearchTypes, 0..) |CT, i| {
                    if (CT == T) return @ptrCast(@alignCast(self.components[i]));
                }
                @panic("Type not found in query");
            }
        };
    };
}
