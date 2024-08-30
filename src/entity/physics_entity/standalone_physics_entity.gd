class_name StandalonePhysicsEntity
extends PhysicsEntity

static func get_type() -> ObjectType:
    return (StandalonePhysicsEntity as Object).get_meta(OBJECT_TYPE_META)

# TODO shape_idx -> PartialPhysicsEntity

var physics_body_rid: RID
var physics_body_direct_state: PhysicsDirectBodyState3D
var physics_child_entities: Array[PartialPhysicsEntity]
var in_physics_transform_sync: bool = false

var physics_last_transform: Transform3D

func _object_init() -> void:
    super._object_init()
    physics_body_rid = PhysicsServer3D.body_create()
    PhysicsServer3D.body_attach_object_instance_id(physics_body_rid, get_instance_id())

func _get_physics_body_rid() -> RID:
    return physics_body_rid

func _get_body_direct_state() -> PhysicsDirectBodyState3D:
    if not physics_body_direct_state:
        physics_body_direct_state = PhysicsServer3D.body_get_direct_state(physics_body_rid)
    return physics_body_direct_state

func _object_free() -> void:
    if physics_body_rid:
        PhysicsServer3D.free_rid(physics_body_rid)
        physics_body_rid = RID()
    super._object_free()

func _entity_init() -> void:
    super._entity_init()
    __update_physics()
    PhysicsServer3D.body_set_space(physics_body_rid, world.space)

    PhysicsServer3D.body_apply_force(physics_body_rid, Vector3.UP * 100, Vector3.ZERO)

func _entity_deinit() -> void:
    PhysicsServer3D.body_set_space(physics_body_rid, RID())
    super._entity_deinit()

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
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
    if source is StandalonePhysicsEntity and source != self:
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

func physics_child_shape_changed(_child: PhysicsEntity) -> void:
    __update_physics()

func __update_physics() -> void:
    var centroid_sum = Vector3()
    var mass = 0
    for shapeidx in shape_attached_idxs:
        var origin = shape_transforms[shapeidx].origin
        origin = get_relative_transform(self).affine_inverse() * origin
        var shape_mass = shape_masses[shapeidx]
        centroid_sum += origin * shape_mass
        mass += shape_mass
    for child in physics_child_entities:
        for shapeidx in child.shape_attached_idxs:
            var origin = child.shape_transforms[shapeidx].origin
            origin = child.get_relative_transform(self).affine_inverse() * origin
            var shape_mass = child.shape_masses[shapeidx]
            centroid_sum += origin * shape_mass
            mass += shape_mass
    PhysicsServer3D.body_set_param(physics_body_rid, PhysicsServer3D.BODY_PARAM_CENTER_OF_MASS, \
            centroid_sum / mass)
    PhysicsServer3D.body_set_param(physics_body_rid, PhysicsServer3D.BODY_PARAM_MASS, mass)

func _snapshot_check(stream: Stream) -> bool:
    if super._snapshot_check(stream): return true
    if not linear_velocity.is_equal_approx(stream.get_var()): return true
    if not angular_velocity.is_equal_approx(stream.get_var()): return true
    return false

func _snapshot_save(stream: Stream) -> void:
    super._snapshot_save(stream)
    stream.store_var(linear_velocity, true)
    stream.store_var(angular_velocity, true)

func _snapshot_load(stream: Stream) -> Error:
    var err = super._snapshot_load(stream)
    if err: return err
    linear_velocity = stream.get_var()
    if stream.get_error(): return stream.get_error()
    angular_velocity = stream.get_var()
    if stream.get_error(): return stream.get_error()
    return OK

func _load_data(stream: Stream) -> Error:
    var err = super._load_data(stream)
    if err: return err
    return Utils.load_data_with_version(stream, [func():
        linear_velocity = stream.get_var()
        if stream.get_error(): return stream.get_error()
        angular_velocity = stream.get_var()
        if stream.get_error(): return stream.get_error()
        return OK
    ])

func _save_data(stream: Stream) -> void:
    super._save_data(stream)
    Utils.save_data_with_version(stream, [func():
        stream.store_var(linear_velocity, true)
        stream.store_var(angular_velocity, true)
    ])
