class_name World
extends Object

var world_id: int;
# Vector3i -> Chunk
var chunks: Dictionary = {};

var root_world: bool = false;
var parent_world: World = null;

var physics_space: RID:
    get: return parent_world.physics_space if parent_world else physics_space
var canvas_item: RID

static func create() -> World:
    var world = World.new();
    return world;

func process(delta: float) -> void:
    pass

func physics_process(delta: float) -> void:
    pass

func input(event: InputEvent) -> void:
    pass

func unhandled_input(event: InputEvent) -> void:
    pass

func create_resources() -> void:
    pass

func init_resources() -> void:
    pass

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

