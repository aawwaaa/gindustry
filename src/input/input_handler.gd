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
    
    func _get_move_velocity() -> Vector3:
        return Vector3.ZERO
    func _get_roll_velocity() -> Vector3:
        return Vector3.ZERO

    func get_move_velocity() -> Vector3:
        return _get_move_velocity()
    func get_roll_velocity() -> Vector3:
        return _get_roll_velocity()

class MenuModule extends InputHandlerModule:
    static func get_type() -> StringName:
        return &"Menu"
