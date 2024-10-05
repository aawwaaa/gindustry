class_name Controller
extends Node

signal control_target_changed()

var modules: Dictionary = {}

var entity_ref: RefObjectRef = RefObjectRef.new()
var entity: Entity:
    get: return entity_ref.v
    set(v): entity_ref.v = v
var component_id: int = 0
var component: ControlHandleComponent:
    get: return entity.get_component_by_id(component_id) \
            if entity and entity.has_component_id(component_id) \
            else null

func sync(method: StringName, args: Array[Variant]) -> void:
    Vars.server.sync_node(self, method, args)

func has_module(type: StringName) -> bool:
    return modules.has(type)

func get_module(type: StringName) -> ControllerModule:
    return modules.get(type)

func get_modules() -> Dictionary:
    return modules

func add_module(module: ControllerModule) -> void:
    modules[module._get_type()] = module
    module.controller = self
    add_child(module)

func save_data(stream: Stream) -> void:
    stream.store_64(entity_ref.id)
    stream.store_32(component_id)

func load_data(stream: Stream) -> void:
    entity_ref.id = stream.get_64()
    component_id = stream.get_32()
    await entity_ref.available
    if component:
        component.add_controller(self)
    control_target_changed.emit()

@rpc("authority", "call_remote", "reliable")
func control_to(comp: ControlHandleComponent) -> void:
    if Vars.client.post_to_server(self, "control_to", [comp]): return
    if comp and not comp.check_control(self): return
    if component:
        component.remove_controller(self)
        entity_ref.v = null
        component_id = 0
    if comp:
        comp.add_controller(self)
        entity_ref.v = comp.entity
        component_id = comp.component_id
    control_target_changed.emit()

@rpc("authority", "call_remote", "reliable")
func access_to(target: Variant, method: StringName, args: Array[Variant]) -> void:
    if Vars.client.post_to_server(self, "access_to", [target, method, args]): return
    entity.sync("access_to", [target, method, args])

@rpc("authority", "call_remote", "reliable")
func access_to_self(method: StringName, args: Array[Variant]) -> void:
    if Vars.client.post_to_server(self, "access_to_self", [method, args]): return
    entity.sync("access_to_self", [method, args])

class ControllerModule extends Node:
    static var TYPE:
        get = get_type
    static func get_type() -> StringName:
        return &"Controller"

    var controller: Controller
    var priority: int = 0

    func _ready() -> void:
        name = _get_type()
        set_multiplayer_authority(controller.get_multiplayer_authority())

    func sync(method: StringName, args: Array[Variant]) -> void:
        Vars.server.sync_node(self, method, args)

    func access_to(target: Variant, method: StringName, args: Array[Variant]) -> void:
        controller.access_to(target, method, args)

    func access_to_self(method: StringName, args: Array[Variant]) -> void:
        controller.access_to_self(method, args)

    func _get_type() -> StringName:
        return TYPE
    
    func get_priority() -> float:
        return priority

class MovementModule extends ControllerModule:
    static func get_type() -> StringName:
        return &"Movement"

    var entity_basis: Basis
    var entity_linear_velocity: Vector3
    var entity_angular_velocity: Vector3
    var entity_max_force: Array[float] = [1, 1, 1, 1, 1, 1]
    var entity_max_torque: float = 1
    var entity_mass: float
    var entity_gravity: Vector3

    func normalize_force(force: Vector3) -> Vector3:
        if entity_max_force.size() < 6: return force
        if force.x >= 0: force.x /= entity_max_force[0]
        else: force.x /= entity_max_force[1]
        if force.y >= 0: force.y /= entity_max_force[2]
        else: force.y /= entity_max_force[3]
        if force.z >= 0: force.z /= entity_max_force[4]
        else: force.z /= entity_max_force[5]
        return force

    func _get_move_velocity() -> Vector3:
        return Vector3.ZERO
    func get_move_velocity() -> Vector3:
        var vel = _get_move_velocity()
        if !vel.is_finite():
            push_warning("Invalid move velocity")
            return Vector3.ZERO
        return vel
    func get_move_velocity_normalized() -> Vector3:
        var vel = get_move_velocity()
        if vel == Vector3.ZERO: return vel
        return vel.normalized() if vel.is_finite() \
                else vel.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1)).normalized()

    func _get_roll_velocity() -> Vector3:
        return Vector3.ZERO
    # (x_axis_vel, y_axis_vel, z_axis_vel)
    func get_roll_velocity() -> Vector3:
        var vel = _get_roll_velocity()
        if !vel.is_finite():
            push_warning("Invalid roll velocity")
            return Vector3.ZERO
        return vel
    func get_roll_velocity_normalized() -> Vector3:
        var vel = get_roll_velocity()
        if vel == Vector3.ZERO: return vel
        return vel.normalized() if vel.is_finite() \
                else vel.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1)).normalized()

    static func get_move_velocity_for(comp: ControlHandleComponent) -> Vector3:
        var module = comp.get_module(MovementModule.TYPE)
        if not module: return Vector3.ZERO
        return module.get_move_velocity()
    static func get_move_velocity_normalized_for(comp: ControlHandleComponent) -> Vector3:
        var module = comp.get_module(MovementModule.TYPE)
        if not module: return Vector3.ZERO
        return module.get_move_velocity_normalized()

    static func get_roll_velocity_for(comp: ControlHandleComponent) -> Vector3:
        var module = comp.get_module(MovementModule.TYPE)
        if not module: return Vector3.ZERO
        return module.get_roll_velocity()
    static func get_roll_velocity_normalized_for(comp: ControlHandleComponent) -> Vector3:
        var module = comp.get_module(MovementModule.TYPE)
        if not module: return Vector3.ZERO
        return module.get_roll_velocity_normalized()

class CameraOutputModule extends ControllerModule:
    static func get_type() -> StringName:
        return &"CameraOutput"

    var camera_world: World:
        get: return controller.entity.world if controller.entity else null
    var camera_transform: Transform3D

