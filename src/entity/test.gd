class_name TestEntity
extends Entity

static func _static_init() -> void:
    mesh.size = Vector3(1, 1, 1)

static func get_type() -> ObjectType:
    return (TestEntity as Object).get_meta(OBJECT_TYPE_META)

static var mesh = BoxMesh.new()

var rid: RID

func _entity_init() -> void:
    super._entity_init()
    rid = RenderingServer.instance_create()
    RenderingServer.instance_set_base(rid, mesh.get_rid())
    RenderingServer.instance_attach_object_instance_id(rid, get_instance_id())
    RenderingServer.instance_set_scenario(rid, root_world.world_3d.scenario)
    _on_transform_changed(self)

func _entity_deinit() -> void:
    if rid.is_valid(): RenderingServer.free_rid(rid)
    super._entity_deinit()

func _physics_process(delta: float) -> void:
    if not object_ready: return
    #transform = transform.translated(Vector3.FORWARD * delta)

func _on_transform_changed(source: Entity) -> void:
    super._on_transform_changed(source)
    if rid.is_valid(): RenderingServer.instance_set_transform(rid, get_global_transform())
