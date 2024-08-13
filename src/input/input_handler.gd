class_name InputHandler
extends Node

static var input_handlers: Dictionary = {}
# static signal input_handler_added(InputHandlerMeta)
static var input_handler_added: StaticSignal = StaticSignal.new()

class InputHandlerMeta extends RefCounted:
    var id: StringName
    var tr_name: String
    var create: Callable

    func _init(dict: Dictionary) -> void:
        id = dict["id"]
        tr_name = dict["tr_name"] if dict.has("tr_name") else id
        create = dict["create"]

static func register_input_handler(meta: InputHandlerMeta) -> void:
    input_handlers[meta.id] = meta

    input_handler_added.emit([meta])

var modules: Dictionary = {}
var modules_ordered: Array[InputHandlerModule] = []

var player: Player:
    get: return Vars.game.player
var controller: PlayerController:
    get: return player.get_controller() if player else null
var entity: Entity:
    get: return controller.entity if controller else null
var component: ControlHandleComponent:
    get: return controller.component if controller else null

func add_module(module: InputHandlerModule) -> void:
    modules[module._get_type()] = module
    module.name = module._get_type()
    module.handler = self
    modules_ordered.append(module)
    add_child(module)

func get_module(type: StringName) -> InputHandlerModule:
    return modules.get(type)

func has_module(type: StringName) -> bool:
    return modules.has(type)

func _add_ui(node: CanvasLayer) -> void:
    for module in modules_ordered:
        var sub = Control.new()
        sub.name = module._get_type()
        sub.set_anchors_preset(Control.PRESET_FULL_RECT)
        sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
        module._add_ui(sub)
        node.add_child(sub)
func add_ui(node: CanvasLayer) -> void:
    _add_ui(node)

func _remove_ui(node: CanvasLayer) -> void:
    for module in modules_ordered:
        var sub = node.get_node(str(module._get_type()))
        module._remove_ui(sub)
        node.remove_child(sub)
func remove_ui(node: CanvasLayer) -> void:
    _remove_ui(node)

func _extend_from(handler: InputHandler) -> void:
    for module in handler.modules_ordered:
        if not has_module(module._get_type()): continue
        get_module(module._get_type())._extend_from(module)
func extend_from(handler: InputHandler) -> void:
    _extend_from(handler)

func push_input(input: InputEvent) -> bool:
    for module in modules_ordered:
        if not module.enabled: continue
        if module._handle_input(input): return true
    return false

func push_unhandled_input(input: InputEvent) -> bool:
    for module in modules_ordered:
        if not module.enabled: continue
        if module._handle_unhandled_input(input): return true
    return false

func _enter_game() -> void: pass
func enter_game() -> void:
    _enter_game()
    for module in modules_ordered:
        module._enter_game()

func _exit_game() -> void: pass
func exit_game() -> void:
    _exit_game()
    for module in modules_ordered:
        module._exit_game()

class InputHandlerModule extends Node:
    static var TYPE: StringName:
        get = get_type
    static func get_type() -> StringName:
        return &"InputHandler"

    var enabled: bool = true
    var handler: InputHandler

    var player: Player:
        get: return handler.player
    var controller: PlayerController:
        get: return handler.controller
    var entity: Entity:
        get: return handler.entity
    var component: ControlHandleComponent:
        get: return handler.component

    func _get_type() -> StringName:
        return TYPE
    func _handle_input(_input: InputEvent) -> bool:
        return false
    func _handle_unhandled_input(_input: InputEvent) -> bool:
        return false

    func _call_module(_method: StringName, _args: Array[Variant]) -> void:
        pass
    func call_module(method: StringName, args: Array[Variant]) -> void:
        if not enabled: return
        _call_module(method, args)

    func _extend_from(_module: InputHandlerModule) -> void:
        pass
    func _add_ui(_node: Control) -> void:
        pass
    func _remove_ui(_node: Control) -> void:
        pass
    
    func _enter_game() -> void:
        pass
    func _exit_game() -> void:
        pass

class MovementModule extends InputHandlerModule:
    static func get_type() -> StringName:
        return &"Movement"

    var sync_to_controller: bool = true

    func _get_input_move_velocity() -> Vector3:
        return Vector3.ZERO
    func _get_input_roll_velocity() -> Vector3:
        return Vector3.ZERO
    
    func _get_move_velocity() -> Vector3:
        return Vector3.ZERO
    func _get_roll_velocity() -> Vector3:
        return Vector3.ZERO

    func get_input_move_velocity() -> Vector3:
        return _get_input_move_velocity()
    func get_input_roll_velocity() -> Vector3:
        return _get_input_roll_velocity()

    func get_move_velocity() -> Vector3:
        return _get_move_velocity()
    func get_roll_velocity() -> Vector3:
        return _get_roll_velocity()

    func get_move_velocity_normalized() -> Vector3:
        var vel = get_move_velocity()
        if vel == Vector3.ZERO: return vel
        return vel.normalized() if vel.is_finite() \
                else vel.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1)).normalized()
    func get_roll_velocity_normalized() -> Vector3:
        var vel = get_roll_velocity()
        if vel == Vector3.ZERO: return vel
        return vel.normalized() if vel.is_finite() \
                else vel.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1)).normalized()

    static func get_move_velocity_for(target_handler: InputHandler) -> Vector3:
        if not target_handler.has_module(TYPE): return Vector3.ZERO
        return target_handler.get_module(TYPE).get_move_velocity()
    static func get_move_velocity_normalized_for(target_handler: InputHandler) -> Vector3:
        if not target_handler.has_module(TYPE): return Vector3.ZERO
        return target_handler.get_module(TYPE).get_move_velocity_normalized()
    
    static func get_roll_velocity_for(target_handler: InputHandler) -> Vector3:
        if not target_handler.has_module(TYPE): return Vector3.ZERO
        return target_handler.get_module(TYPE).get_roll_velocity()
    static func get_roll_velocity_normalized_for(target_handler: InputHandler) -> Vector3:
        if not target_handler.has_module(TYPE): return Vector3.ZERO
        return target_handler.get_module(TYPE).get_roll_velocity_normalized()

class MenuModule extends InputHandlerModule:
    static func get_type() -> StringName:
        return &"Menu"

class CameraModule extends InputHandlerModule:
    static func get_type() -> StringName:
        return &"Camera"

    var camera: CameraController
    var get_from_controller: bool = true

    var world: World:
        get: return camera.world
        set(v): camera.world = v
    var transform: Transform3D:
        get: return camera.transform
        set(v): camera.transform = v

    func _init() -> void:
        camera = CameraController.new()
        camera.name = "CameraController"
        add_child(camera)
