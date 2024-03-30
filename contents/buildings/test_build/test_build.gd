extends Node2D

@export var entity: Entity

func get_entity() -> Entity:
    return entity

func _on_building_input_operation(operation: String, args: Array) -> void:
    if operation == "open_panel":
        Global.input_handler.call_input_processor("item", "access_target_ui", [self])
