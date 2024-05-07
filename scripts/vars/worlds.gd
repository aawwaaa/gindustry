class_name Vars_Worlds
extends Vars.Vars_Object

var worlds: Dictionary = {}

func get_world_or_null(world_id: int) -> World:
    if not Vars.objects.has_object(world_id) \
            or not (Vars.objects.get_object_or_null(world_id) is World):
        return null;
    return Vars.objects.get_object_or_null(world_id) 

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
    return world;

func create_world() -> World:
    var world = World.create();
    world.root_world = true;
    return world;

func cleanup() -> void:
    for world in worlds.values():
        world.free()
    worlds = {};

func load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        for _1 in stream.get_32():
            var world_id = stream.get_64();
            var world = World.create();
            # TODO load_object
            world.world_id = world_id;
#             worlds[world_id] = world
            world.load_data(stream);
            world.init_resources()
    ])

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_32(worlds.size())
        for world in worlds.values():
            stream.store_64(world.world_id)
            world.save_data(world)
    ])

