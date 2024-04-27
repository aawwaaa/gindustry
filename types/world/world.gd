class_name World
extends RefCounted

var world_id: int;
# Vector3i -> Chunk
var chunks: Dictionary = {};

static func create() -> World:
    var world = World.new();
    return world;
