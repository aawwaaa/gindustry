class_name Vars_Worlds
extends Vars.Vars_Object

signal worlds_changed()
signal toggled_world_changed(world: World)

var logger: Log.Logger = Log.register_logger("Worlds_LogSource")

var worlds: Dictionary = {}
var current_toggled_world: World:
    set(v): current_toggled_world = v; toggled_world_changed.emit(v)

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
    var world = World.TYPE.create(false);
    world.is_root_world = true;
    world.object_create()
    worlds_changed.emit()
    return world;

func reset() -> void:
    for world in worlds.values():
        if not is_instance_valid(world): continue
        world.free()
    current_toggled_world = null
    worlds = {};

func load_data(stream: Stream) -> Error:
    return Utils.load_data_with_version(stream, [func():
        var size = stream.get_32()
        if stream.get_error(): return stream.get_error()
        for _1 in size:
            var world = Vars.objects.load_object(stream)
            if Vars.objects.err: return Vars.objects.err
            if not (world is World):
                logger.error(tr("Worlds_UnknownWorldObject {id}").format({id = world.object_id}))
                return ERR_INVALID_DATA
            worlds[world.object_id] = world
        worlds_changed.emit()
        return OK
    ])

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_32(worlds.size())
        for world in worlds.values():
            Vars.objects.save_object(stream, world)
    ])

