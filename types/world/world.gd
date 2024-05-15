class_name World
extends Entity

const TILE_SIZE = 0.5
const TILE_SIZE_VECTOR = Vector3.ONE * TILE_SIZE

static var world_object_type: Vars_Objects.GDScriptObjectType

static func _static_init() -> void:
    world_object_type = Vars_Objects.GDScriptObjectType.new()
    world_object_type.uuid = "gindustry-builtin-world"
    world_object_type.type_script = World
    Vars_Objects.add_object_type(world_object_type)

static func get_type() -> Vars_Objects.ObjectType:
    return world_object_type

var is_root_world: bool = false;

var world_3d: World3D:
    get: return  parent_entity.world_3d if parent_entity and parent_entity != self else world_3d
    set(v): world_3d = v;

static func create() -> World:
    return TYPE.create();

func _object_create() -> void:
    super._object_create()

func _object_init() -> void:
    super._object_init()
    Vars.worlds.worlds[object_id] = self 
    if is_root_world:
        self.world = self
        world_3d = World3D.new()

func _object_ready() -> void:
    if object_ready: return
    super._object_ready()

func _object_free() -> void:
    super._object_free()

func toggle_to() -> void:
    if Vars.worlds.current_toggled_world == root_world: return
    Vars.worlds.current_toggled_world = root_world
    get_viewport().world_3d = world_3d

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        is_root_world = stream.get_8() == 1;
        for _1 in range(stream.get_64()):
            var object = Vars.objects.load_object(stream)
            add_child_entity(object)
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_8(1 if is_root_world else 0);
        stream.store_64(child_entities.size())
        for child in child_entities:
            Vars.objects.save_object(stream, child)
    ])

