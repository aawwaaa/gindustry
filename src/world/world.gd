class_name World
extends Entity

const TILE_SIZE = 0.25
const TILE_SIZE_VECTOR = Vector3.ONE * TILE_SIZE
const CHUNK_SIZE = 32
const CHUNK_SIZE_VECTOR = Vector3.ONE * CHUNK_SIZE

static var world_object_type: GDScriptObjectType

static func _static_init() -> void:
    world_object_type = GDScriptObjectType.new()
    world_object_type.id = "gindustry-builtin-world"
    world_object_type.type_script = World
    Vars_Objects.add_object_type(world_object_type)

static func get_type() -> ObjectType:
    return world_object_type

var is_root_world: bool = false;

var world_3d: World3D:
    get: return  parent_entity.world_3d if parent_entity and parent_entity != self else world_3d
    set(v): world_3d = v;
var camera: RID:
    get: return parent_entity.camera if parent_entity and parent_entity != self else camera
    set(v): camera = v

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
        camera = RenderingServer.camera_create()
        RenderingServer.camera_set_cull_mask(camera, 1)
        RenderingServer.camera_set_transform(camera, Transform3D.IDENTITY)

func _object_ready() -> void:
    if object_ready: return
    super._object_ready()

func _object_free() -> void:
    super._object_free()
    if is_root_world:
        if Vars.worlds.current_toggled_world == self:
            get_viewport().world_3d = null
            Vars.worlds.current_toggled_world = null
        world_3d.queue_free()
        RenderingServer.free_rid(camera)

func toggle_to() -> void:
    if Vars.worlds.current_toggled_world == root_world: return
    Vars.worlds.current_toggled_world = root_world

    var viewport = get_viewport()
    RenderingServer.viewport_set_scenario(viewport.get_viewport_rid(), root_world.world_3d.scenario)
    RenderingServer.viewport_attach_camera(viewport.get_viewport_rid(), root_world.camera)

func _load_data(stream: Stream) -> Error:
    super._load_data(stream)
    return Utils.load_data_with_version(stream, [func():
        is_root_world = stream.get_8() == 1;
        if stream.get_error(): return stream.get_error()
        return OK
    ])

func _save_data(stream: Stream) -> void:
    super._save_data(stream)
    Utils.save_data_with_version(stream, [func():
        stream.store_8(1 if is_root_world else 0);
    ])

