class_name InputHandler
extends Node

class InputHandlerMeta extends RefCounted:
    var input_handler: GDScript
    var tr_name: String

    func _init(attrs: Dictionary) -> void:
        input_handler = attrs["input_handler"]
        tr_name = attrs["tr_name"]

static var input_handlers: Dictionary = {}
static var add_input_handler_listener: Callable;

static func register_input_handler(id: String, meta: InputHandlerMeta) -> void:
    input_handlers[id] = meta

    if add_input_handler_listener:
        add_input_handler_listener.call(id, meta)

signal controller_target_changed(target: ControllerAdapter, from: ControllerAdapter)
signal controller_target_entity_changed(entity: Entity, from: Entity)

var input_processors: Dictionary = {}

var player: Player:
    get: return Game.current_player
var controller: PlayerController:
    get: return player.get_controller() if player else null
var target: ControllerAdapter:
    get: return controller.target if controller else null
var entity: Entity:
    get: return target.entity_node if target else null

func _load_ui(node: Control) -> void:
    pass

func _unload_ui(node: Control) -> void:
    for child in node.get_children():
        child.queue_free()

func _ready() -> void:
    Game.current_player_changed.connect(_on_player_changed)

func _accept_input(name: StringName, func_name: StringName, args: Array = []) -> bool:
    return true

func call_input_processor(name: StringName, func_name: StringName, args: Array = []) -> void:
    if not input_processors.has(name): return
    if not _accept_input(name, func_name, args): return
    var processor = input_processors[name]
    if not processor or not processor.has_method(func_name): return
    processor[func_name].callv(args)

func _on_player_changed(player: Player, from: Player) -> void:
    Utils.signal_dynamic_connect(controller, from.get_controller() if from else null,
            "target_changed", _on_controller_target_changed)
    _on_controller_target_changed(target, from.get_controller().target if from else null)

func _on_controller_target_changed(target: ControllerAdapter, from: ControllerAdapter) -> void:
    controller_target_changed.emit(target, from)
    controller_target_entity_changed.emit(target.entity_node if target else null, \
            from.entity_node if from else null)

func _unhandled_input(event: InputEvent) -> void:
    if player == null: return
    _handle_unhandled_input(event)

func _input(event: InputEvent) -> void:
    if player == null: return
    _handle_input(event)

func _process(delta: float) -> void:
    if player == null: return
    _handle_process(delta)

func _handle_unhandled_input(event: InputEvent) -> void:
    pass

func _handle_input(event: InputEvent) -> void:
    pass

func _handle_process(delta: float) -> void:
    pass
