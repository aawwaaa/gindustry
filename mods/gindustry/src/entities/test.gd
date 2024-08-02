class_name Gindustry_Entity_Test
extends StandalonePhysicsEntity

static func get_type() -> ObjectType:
    return (Gindustry_Entity_Test as Object).get_meta(OBJECT_TYPE_META)

var shape_rid: RID
var shape: int

var box: BoxMesh
var instance: RID

func _object_init() -> void:
    super._object_init()
    shape_rid = PhysicsServer3D.box_shape_create()
    PhysicsServer3D.shape_set_data(shape_rid, Vector3(1, 1, 1) / 2)
    
    shape = add_shape(shape_rid, Transform3D.IDENTITY, 1)

    box = BoxMesh.new()
    box.size = Vector3(1, 1, 1)
    box.material = StandardMaterial3D.new()

    box.material.albedo_color = Color(1, 0, 0)
    instance = RenderingServer.instance_create()
    RenderingServer.instance_set_base(instance, box.get_rid())

    PhysicsServer3D.body_set_mode(physics_body_rid, PhysicsServer3D.BODY_MODE_RIGID)
    PhysicsServer3D.body_set_collision_mask(physics_body_rid, 1)
    PhysicsServer3D.body_set_collision_layer(physics_body_rid, 1)

func _object_free() -> void:
    PhysicsServer3D.free_rid(shape_rid)
    RenderingServer.free_rid(instance)

    super._object_free()

func _entity_init() -> void:
    super._entity_init()

    RenderingServer.instance_set_scenario(instance, world.scenario)

func _entity_deinit() -> void:
    super._entity_deinit()

func _load_data(stream: Stream) -> Error:
    var err = super._load_data(stream)
    if err: return err
    return Utils.load_data_with_version(stream, [])

func _save_data(stream: Stream) -> void:
    super._save_data(stream)
    Utils.save_data_with_version(stream, [])

func _on_transform_changed(source: Entity) -> void:
    super._on_transform_changed(source)

    RenderingServer.instance_set_transform(instance, get_global_transform())

