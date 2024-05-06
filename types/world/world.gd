class_name World
extends Entity

var world_id: int;
# Vector3i -> Chunk
var chunks: Dictionary = {};

var root_world: bool = false;

var physics_space: RID:
    get: return world.physics_space if world else physics_space

static func create() -> World:
    var world = World.new();
    return world;

func create_resources() -> void:
    init_resources()

func init_resources() -> void:
    name = "World#" + str(world_id)

func free_resources() -> void:
    pass

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

