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

# Vector3i -> Chunk
var chunks: Dictionary = {};

var root_world: bool = false;

var physics_space: RID:
    get: return world.physics_space if world else physics_space

static func create() -> World:
    return TYPE.create();

func _object_create() -> void:
    super._object_create()

func _object_init() -> void:
    super._object_init()
    Vars.worlds.worlds[object_id] = self
    if root_world: self.world = self

func _object_ready() -> void:
    if object_ready: return
    super._object_ready()

func _object_free() -> void:
    super._object_free()
    for chunk in chunks.values():
        chunk.free()

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        root_world = stream.get_8() == 1;
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.put_8(1 if root_world else 0);
    ])

