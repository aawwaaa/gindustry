class_name StandalonePhysicsEntity
extends PhysicsEntity

var physics_body_rid: RID
var physics_child_entities: Array[PartialPhysicsEntity]
var in_physics_transform_sync: bool = false

var physics_last_transform: Transform3D

# TODO phychild(shapes_changed) -> calculate_mass & calcuate_centroid

func _object_init() -> void:
    super._object_init()
    physics_body_rid = PhysicsServer3D.body_create()
    PhysicsServer3D.body_attach_object_instance_id(physics_body_rid, get_instance_id())

func _get_physics_body_rid() -> RID:
    return physics_body_rid

func _object_free() -> void:
    if physics_body_rid:
        PhysicsServer3D.free_rid(physics_body_rid)
        physics_body_rid = RID()
    super._object_free()

func _entity_init() -> void:
    super._entity_init()
    __update_physics()
    PhysicsServer3D.body_set_space(physics_body_rid, world.world_3d.space)

func _entity_deinit() -> void:
    PhysicsServer3D.body_set_space(physics_body_rid, RID())
    super._entity_deinit()

func _physics_process(_delta: float) -> void:
    if not entity_active: return
    var rid = get_physics_body_rid()
    if not rid.is_valid(): return
    var new_transform = PhysicsServer3D.body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
    physics_transform_changed(new_transform)

func physics_transform_changed(new_transform: Transform3D) -> void:
    if physics_last_transform.is_equal_approx(new_transform): return
    physics_last_transform = new_transform
    in_physics_transform_sync = true
    new_transform = parent_entity.get_global_transform().affine_inverse() * new_transform
    transform = new_transform
    in_physics_transform_sync = false

func _on_transform_changed(source: Entity) -> void:
    super._on_transform_changed(source)
    if in_physics_transform_sync: return
    if source is StandalonePhysicsEntity:
        var rid = get_physics_body_rid()
        var new_transform = PhysicsServer3D.body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
        physics_transform_changed(new_transform)
        return
    var global_transform = get_global_transform()
    PhysicsServer3D.body_set_state(physics_body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, \
            global_transform)
    physics_last_transform = global_transform

func add_physics_child(child: PartialPhysicsEntity) -> void:
    physics_child_entities.append(child)
    if entity_active: __update_physics()

func remove_physics_child(child: PartialPhysicsEntity) -> void:
    physics_child_entities.erase(child)
    if entity_active: __update_physics()

func physics_child_shape_changed(_child: PartialPhysicsEntity) -> void:
    __update_physics()

func __update_physics() -> void:
    var centroid_sum = Vector3()
    var mass = 0
    var process = func(entity: PhysicsEntity) -> void:
        for shapeidx in entity.shape_attached_idxs:
            var origin = entity.shape_transforms[shapeidx].origin
            origin = entity.get_relative_transform(self).affine_inverse() * origin
            var shape_mass = entity.shape_masses[shapeidx]
            centroid_sum += origin * shape_mass
            mass += shape_mass
    process.call(self)
    for child in physics_child_entities:
        process.call(child)
    PhysicsServer3D.body_set_param(physics_body_rid, PhysicsServer3D.BODY_PARAM_CENTER_OF_MASS, \
            centroid_sum / mass)
    PhysicsServer3D.body_set_param(physics_body_rid, PhysicsServer3D.BODY_PARAM_MASS, mass)


