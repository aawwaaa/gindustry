class_name Vars_Worlds
extends Vars.Vars_Object

var logger: Log.Logger = Log.register_logger("Worlds_LogSource")

var worlds: Dictionary = {}
var current_toggled_world: World

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
    var world = World.TYPE.create(true);
    world.is_root_world = true;
    world.handle_create()
    Vars.objects.make_ready(world)
    return world;

func reset() -> void:
    for world in worlds.values():
        world.free()
    current_toggled_world = null
    worlds = {};

func load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        for _1 in stream.get_32():
            var world = Vars.objects.load_object(stream)
            if not (world is World):
                logger.error(tr("Worlds_UnknownWorldObject {id}").format({id = world.object_id}))
                continue
            worlds[world.object_id] = world
    ])

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_32(worlds.size())
        for world in worlds.values():
            Vars.objects.save_object(stream, world)
    ])

