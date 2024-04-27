class_name World
extends RefCounted

var world_id: int;
var root_world: bool = false;
# Vector3i -> Chunk
var chunks: Dictionary = {};

static func create() -> World:
    var world = World.new();
    return world;

func load_data(stream: Stream) -> void:
    pass

func save_data(stream: Stream) -> void:
    pass


