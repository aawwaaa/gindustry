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

# signal controller_target_changed(target: ControllerAdapter, from: ControllerAdapter)
# signal controller_target_entity_changed(entity: Entity, from: Entity)
# signal focused_entity_changed(entity: Entity, from: Entity)

var input_processors: Dictionary = {}
# var interacting_entities: Array[Entity] = []
# var interacting_adapters: Array[EntityAdapter] = []
var configuring_target: Object = null;

var player: Player:
    get: return Game.current_player
# var controller: PlayerController:
#     get: return player.get_controller() if player else null
# var target: ControllerAdapter:
#     get: return controller.target if controller else null
# var entity: Entity:
#     get: return target.entity_node if target else null

var world_pos: Vector2;

func _load_ui(node: Control) -> void:
    pass

func _unload_ui(node: Control) -> void:
    for child in node.get_children():
        child.queue_free()

func _ready() -> void:
    Game.current_player_changed.connect(_on_player_changed)
#     Game.signal_reset_game.connect(_on_reset_game)

# func _on_reset_game() -> void:
#     interacting_entities.clear()
# 
# func add_interacting_entity(entity: Entity) -> void:
#     if entity in interacting_entities: return
#     var focused = get_focused_entity()
#     interacting_entities.append(entity)
#     update_focused_entity(focused)
# 
# func remove_interacting_entity(entity: Entity) -> void:
#     if entity not in interacting_entities: return
#     var focused = get_focused_entity()
#     interacting_entities.erase(entity)
#     update_focused_entity(focused)
# 
# func add_interacting_adapter(adapter: EntityAdapter) -> void:
#     if adapter in interacting_adapters: return
#     interacting_adapters.append(adapter)
# 
# func remove_interacting_adapter(adapter: EntityAdapter) -> void:
#     if adapter not in interacting_adapters: return
#     interacting_adapters.erase(adapter)

func set_configuring_target(target: Object) -> bool:
    if configuring_target: return false
    configuring_target = target
    return true

func clear_configuring_target() -> void:
    configuring_target = null

# func get_interacting_target() -> Node:
#     if configuring_target: return configuring_target
#     if interacting_adapters.size() != 0: return interacting_adapters.back()
#     if interacting_entities.size() == 0: return null
#     return interacting_entities.back()
# 
# func get_focused_entity() -> Entity:
#     if interacting_entities.size() == 0: return null
#     return interacting_entities.back()
# 
# func _get_focused_tile() -> Tile:
#     return entity.world.get_tile_or_null(Tile.to_tile_pos(world_pos)) if entity else null
# 
# func get_focused_tile() -> Tile:
#     return _get_focused_tile()
# 
# func update_focused_entity(old: Entity) -> void:
#     if old == get_focused_entity(): return
#     focused_entity_changed.emit(get_focused_entity(), old)

# func interact_operate(operation: String, args: Array[Variant] = []) -> void:
#     var target = get_interacting_target()
#     if not target: return
#     target.input_operate(operation, args)
# 
func _extend_properties(from: InputHandler) -> void:
#     configuring_target = from.configuring_target
#     interacting_entities = from.interacting_entities
#     interacting_adapters = from.interacting_adapters
    pass

func extend_properties(from: InputHandler) -> void:
    _extend_properties(from)

func _accept_input(name: StringName, func_name: StringName, args: Array = []) -> bool:
    return true

func call_input_processor(name: StringName, func_name: StringName, args: Array = []) -> void:
    if not input_processors.has(name): return
    if not _accept_input(name, func_name, args): return
    var processor = input_processors[name]
    if not processor or not processor.has_method(func_name): return
    processor[func_name].callv(args)

func call_interact_processor(func_name: StringName, args: Array = []) -> void:
    call_input_processor(InputInteracts.INTERACT_PROCESSOR, func_name, args)

func interact_access_target_ui(target: Variant) -> void:
    call_input_processor(InputInteracts.INTERACT_PROCESSOR, InputInteracts.INTERACT_ACCESS_TARGET_UI, [target])

func interact_clear_access_target() -> void:
    call_input_processor(InputInteracts.INTERACT_PROCESSOR, InputInteracts.INTERACT_CLEAR_ACCESS_TARGET, [])

func interact_access_and_operate(args: Array = []) -> void:
    call_input_processor(InputInteracts.INTERACT_PROCESSOR, InputInteracts.INTERACT_ACCESS_AND_OPERATE, args)

func _on_player_changed(player: Player, from: Player) -> void:
    pass
#     Utils.signal_dynamic_connect(controller, from.get_controller() if from else null,
#             "target_changed", _on_controller_target_changed)
#     _on_controller_target_changed(target, from.get_controller().target if from else null)
# 
# func _on_controller_target_changed(target: ControllerAdapter, from: ControllerAdapter) -> void:
#     controller_target_changed.emit(target, from)
#     controller_target_entity_changed.emit(target.entity_node if target else null, \
#             from.entity_node if from else null)

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
