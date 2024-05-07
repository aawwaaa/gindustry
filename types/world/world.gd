class_name World
extends Entity

static var world_object_type: Vars_Objects.GDScriptObjectType

static func _static_init() -> void:
    world_object_type = Vars.objects.GDScriptObjectType.new()
    world_object_type.uuid = "gindustry-builtin-world"
    world_object_type.type_script = World

static func get_type() -> Vars_Objects.ObjectType:
    return world_object_type

# Vector3i -> Chunk
var chunks: Dictionary = {};

var root_world: bool = false;

var physics_space: RID:
    get: return world.physics_space if world else physics_space

static func create() -> World:
    return TYPE.create();

func create_resources() -> void:
    super.create_resource()
    init_data()

func init_data() -> void:
    name = "World#" + str(entity_id)

func init_resources() -> void:
    super.init_resource()
    init_data()
    Vars.worlds.worlds[entity_id] = self

func free_resources() -> void:
    super.free_resource()

func free() -> void:
    for chunk in chunks.values():
        chunk.free()
    free_resources()
    super.free()

func load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        root_world = stream.get_8() == 1;
    ])
    init_resources()

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.put_8(1 if root_world else 0);
    ])

