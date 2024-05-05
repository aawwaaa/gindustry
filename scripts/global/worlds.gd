class_name G_Worlds
extends G.G_Object

var worlds: Dictionary = {}

var world_inc_id = 1;
var entity_inc_id = 1;

func get_world_or_null(world_id: int) -> World:
    if not worlds.has(world_id):
        return null;
    return worlds[world_id];

func get_world(world_id: int) -> World:
    var world = get_world_or_null(world_id)
    if world:
        return world;
#     if not world_load_source:
#         return null;
    @warning_ignore("redundant_await")
#     world = await world_load_source._load_world(world_id);
    if not world:
        return null;
    worlds[world_id] = world;
    return world;

func create_world() -> World:
    var world = World.create();
    world.world_id = world_inc_id;
    world_inc_id += 1;
    world.root_world = true;
    worlds[world.world_id] = world;
    world.create_resources()
    return world;

func cleanup() -> void:
    for world in worlds.values():
        world.free()
    world_inc_id = 1;
    entity_inc_id = 1;
    worlds = {};

func load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        world_inc_id = stream.get_32();
        entity_inc_id = stream.get_64();
        for _1 in stream.get_32():
            var world_id = stream.get_32();
            var world = World.create();
            world.world_id = world_id;
            worlds[world_id] = world
            world.load_data(stream);
    ])

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_32(world_inc_id)
        stream.store_64(entity_inc_id)
        stream.store_32(worlds.size())
        for world in worlds.values():
            stream.store_32(world.world_id)
            world.save_data(world)
    ])

