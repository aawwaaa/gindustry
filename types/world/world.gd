class_name World
extends Object

var world_id: int;
# Vector3i -> Chunk
var chunks: Dictionary = {};

var root_world: bool = false;
var parent_world: World = null;

var world3d: World3D = null:
    get:
        var current = self;
        while not current.root_world: current = current.parent_world;
        return current.world3d;
    set(v):
        var current = self;
        while not current.root_world: current = current.parent_world;
        current.world3d = v;
var viewport: RID;

static func create() -> World:
    var world = World.new();
    return world;

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

