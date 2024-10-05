class_name PhysicsEntity
extends Entity

signal shape_data_changed(shapeidx: int)

static func get_type() -> ObjectType:
    return (PhysicsEntity as Object).get_meta(OBJECT_TYPE_META)

var direct_state: PhysicsDirectBodyState3D:
    get = get_body_direct_state
var linear_velocity: Vector3:
    get: return direct_state.linear_velocity if direct_state else Vector3.ZERO
    set(v): PhysicsServer3D.body_set_state(get_physics_body_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, v)

var angular_velocity: Vector3:
    get: return direct_state.angular_velocity if direct_state else Vector3.ZERO
    set(v): PhysicsServer3D.body_set_state(get_physics_body_rid(), PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, v)

func _get_physics_body_rid() -> RID:
    return RID()

func get_physics_body_rid() -> RID:
    return _get_physics_body_rid()

func _get_body_direct_state() -> PhysicsDirectBodyState3D:
    return null

func get_body_direct_state() -> PhysicsDirectBodyState3D:
    return _get_body_direct_state()

func get_parent_standalone_physics_entity() -> StandalonePhysicsEntity:
    var curr = self
    while curr:
        if curr is StandalonePhysicsEntity:
            return curr
        curr = curr.parent_entity
    return null

var shape_inc_idx: int = 1
var shapes: Dictionary = {}
var shape_transforms: Dictionary = {}
var shape_attached_idxs: Dictionary = {}
var shape_masses: Dictionary = {}

func __attach_shape(shapeidx: int) -> void:
    PhysicsServer3D.body_add_shape(get_physics_body_rid(), \
        shapes[shapeidx], Transform3D.IDENTITY)
    shape_attached_idxs[shapeidx] = PhysicsServer3D.body_get_shape_count(get_physics_body_rid()) - 1
    get_parent_standalone_physics_entity().physics_shape_idx_to_entity[shape_attached_idxs[shapeidx]] = self
    __update_shape(shapeidx)

func __update_shape(shapeidx: int) -> void:
    var parent = get_parent_standalone_physics_entity()
    var shape_local = get_relative_transform(parent) * shape_transforms[shapeidx]
    PhysicsServer3D.body_set_shape_transform(get_physics_body_rid(), \
        shape_attached_idxs[shapeidx], shape_local)
    shape_data_changed.emit(shapeidx)
    parent.physics_child_shape_changed(self)

func __detach_shape(shapeidx: int) -> void:
    var parent = get_parent_standalone_physics_entity()
    PhysicsServer3D.body_remove_shape(get_physics_body_rid(), shape_attached_idxs[shapeidx])
    parent.physics_shape_idx_to_entity.erase(shape_attached_idxs[shapeidx])
    var idx = shape_attached_idxs[shapeidx]
    shape_attached_idxs.erase(shapeidx)
    for entity in parent.physics_entities:
        var idxs = entity.shape_attached_idxs
        for sidx in idxs:
            if idxs[sidx] > idx:
                idxs[sidx] -= 1
                parent.physics_shape_idx_to_entity[idxs[sidx]] = entity

func add_shape(shape: RID, shape_transform: Transform3D, mass: float = 0) -> int:
    var idx = shape_inc_idx
    shapes[idx] = shape
    shape_transforms[idx] = shape_transform
    shape_masses[idx] = mass
    if entity_active:
        __attach_shape(idx)
    shape_inc_idx += 1
    return idx

func set_shape_transform(shapeidx: int, shape_transform: Transform3D) -> void:
    shape_transforms[shapeidx] = shape_transform
    if entity_active and shape_attached_idxs.has(shapeidx):
        __update_shape(shapeidx)

func set_shape_mass(shapeidx: int, mass: float) -> void:
    shape_masses[shapeidx] = mass
    if entity_active and shape_attached_idxs.has(shapeidx):
        __update_shape(shapeidx)

func remove_shape(shapeidx: int) -> void:
    if not shapes.has(shapeidx): return
    if entity_active:
        __detach_shape(shapeidx)
    shapes.erase(shapeidx)
    shape_transforms.erase(shapeidx)
    shape_attached_idxs.erase(shapeidx)

func has_shape(shapeidx: int) -> bool:
    return shapes.has(shapeidx)

func _entity_init() -> void:
    super._entity_init()
    for shapeidx in shapes:
        __attach_shape(shapeidx)

func _entity_deinit() -> void:
    for shapeidx in shape_attached_idxs:
        __detach_shape(shapeidx)
    super._entity_deinit()

func _apply_shape() -> void:
    if entity_type is PhysicsEntityType:
        entity_type.apply_shape(self)

func _object_init() -> void:
    super._object_init()
    _apply_shape()

func _controller_feedback(control_handle: ControlHandleComponent) -> void:
    super._controller_feedback(control_handle)
    var movement = control_handle.get_module(Controller.MovementModule.TYPE)
    if movement:
        var inverse = transform.basis.inverse()
        movement.entity_linear_velocity = inverse * linear_velocity
        movement.entity_angular_velocity = inverse * angular_velocity
        movement.entity_mass = PhysicsServer3D.body_get_param(get_physics_body_rid(), PhysicsServer3D.BODY_PARAM_MASS)
        movement.entity_gravity = inverse * direct_state.total_gravity
