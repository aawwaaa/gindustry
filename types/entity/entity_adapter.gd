class_name EntityAdapter
extends Node

@export var main_node: Node2D
@export var entity_node: Entity
@export var adapter_name: StringName

var configuring: bool = false

func _should_save_data() -> bool:
    return false

func _save_data(stream: Stream) -> void:
    pass

func _load_data(stream: Stream) -> void:
    pass

# operation
func _handle_operation(operation: String, args: Array[Variant] = []) -> void:
    pass

func _handle_adapter_operation(source: EntityAdapter, operation: String, args: Array[Variant] = []) -> void:
    pass

func _handle_remote_operation(source: Entity, operation: String, args: Array[Variant] = []) -> void:
    pass

func _get_main_adapter() -> EntityAdapter:
    return null

func get_main_adapter() -> EntityAdapter:
    return _get_main_adapter()

# building
func _handle_break(unit: BuilderAdapterUnit) -> bool:
    return true

# interact
func _on_area_2d_mouse_entered() -> void:
    Global.input_handler.add_interacting_adapter(self)

func _on_area_2d_mouse_exited() -> void:
    Global.input_handler.remove_interacting_adapter(self)

func _handle_input_operation(operation: String, args: Array[Variant] = []) -> void:
    pass

func _handle_configure_operation(operation: String, args: Array[Variant] = []) -> void:
    pass

func _make_configure_visible(visible: bool) -> void:
    pass

func input_operate(operation: String, args: Array[Variant] = []) -> void:
    _handle_input_operation(operation, args)

func enter_configuring() -> bool: 
    if configuring: return false
    if not Global.input_handler.set_configuring_target(self): return false
    configuring = true
    _make_configure_visible(true)
    return true

func exit_configuring() -> void:
    if not configuring: return
    Global.input_handler.clear_configuring_target()
    configuring = false
    _make_configure_visible(false)

