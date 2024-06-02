class_name TestEntity
extends Entity

static var test_entity_object_type: GDScriptObjectType

static func _static_init() -> void:
    test_entity_object_type = GDScriptObjectType.add("test_entity", TestEntity)

    mesh.size = Vector3(1, 1, 1)

static func get_type() -> ObjectType:
    return test_entity_object_type

static var mesh = BoxMesh.new()

var rid: RID

func _object_init() -> void:
    super._object_init()
    rid = RenderingServer.instance_create()
    RenderingServer.instance_set_base(rid, mesh.get_rid())
    RenderingServer.instance_attach_object_instance_id(rid, get_instance_id())

func _entity_init() -> void:
    super._entity_init()
    RenderingServer.instance_set_scenario(rid, root_world.world_3d.scenario)
    RenderingServer.instance_set_transform(rid, get_global_transform())

func _entity_deinit() -> void:
    if rid.is_valid(): RenderingServer.free_rid(rid)
    super._entity_deinit()

func _process(delta: float) -> void:
    if not object_ready: return
    transform = transform.translated(Vector3.FORWARD * delta)

func _on_transform_changed() -> void:
    super._on_transform_changed()
    if rid.is_valid(): RenderingServer.instance_set_transform(rid, get_global_transform())
