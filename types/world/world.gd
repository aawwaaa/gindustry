class_name World
extends Entity

# Vector3i -> Chunk
var chunks: Dictionary = {};

var root_world: bool = false;

var physics_space: RID:
    get: return world.physics_space if world else physics_space

static func create() -> World:
    var world = World.new();
    return world;

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

