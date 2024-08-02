class_name World
extends Entity

static var logger: Log.Logger

const TILE_SIZE = 0.25
const TILE_SIZE_VECTOR = Vector3.ONE * TILE_SIZE

static func get_type() -> ObjectType:
    return (World as Object).get_meta(OBJECT_TYPE_META)

var is_root_world: bool = false;

var scenario: RID:
    get: return parent_entity.scenario if parent_entity and parent_entity != self else scenario
    set(v): scenario = v;
var space: RID:
    get: return parent_entity.space if parent_entity and parent_entity != self else space
    set(v): space = v;
var camera: RID:
    get: return parent_entity.camera if parent_entity and parent_entity != self else camera
    set(v): camera = v

var chunks: Dictionary = {} # Vector3i -> Chunk

static func create() -> World:
    return TYPE.create();

func _object_create() -> void:
    super._object_create()
    if not logger:
        logger = Log.register_logger("World_LogSource")

func _object_init() -> void:
    super._object_init()
    Vars.worlds.worlds[object_id] = self 
    if is_root_world:
        self.world = self
        scenario = RenderingServer.scenario_create()
        logger.debug("Scenario created: %s" % str(scenario))

        space = PhysicsServer3D.space_create()
        logger.debug("Space created: %s" % str(space))

        camera = RenderingServer.camera_create()
        RenderingServer.camera_set_cull_mask(camera, 1)
        RenderingServer.camera_set_transform(camera, Transform3D.IDENTITY)

func _object_ready() -> void:
    if object_ready: return
    super._object_ready()

    if is_root_world:
        PhysicsServer3D.space_set_active(space, true)
        logger.debug("Space active: %s" % str(space))

func _object_free() -> void:
    if is_root_world:
        if Vars.worlds.current_toggled_world == self:
            RenderingServer.viewport_set_scenario(get_viewport().get_viewport_rid(), RID())
            RenderingServer.viewport_attach_camera(get_viewport().get_viewport_rid(), RID())
            Vars.worlds.current_toggled_world = null
        PhysicsServer3D.free_rid(space)

        RenderingServer.free_rid(camera)
        RenderingServer.free_rid(scenario)
    super._object_free()

func toggle_to() -> void:
    if not object_ready: return

    if Vars.worlds.current_toggled_world == root_world: return
    Vars.worlds.current_toggled_world = root_world

    var viewport = get_viewport()
    RenderingServer.viewport_set_scenario(viewport.get_viewport_rid(), root_world.scenario)
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

