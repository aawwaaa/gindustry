class_name EntityAdapter
extends Node

@export var main_node: Node2D
@export var entity_node: Entity

func _should_save_data() -> bool:
    return false

func _save_data(stream: Stream) -> void:
    pass

func _load_data(stream: Stream) -> void:
    pass

func _handle_operation(operation: String, args: Array[Variant] = []) -> void:
    pass

func _handle_remote_operation(source: Entity, operation: String, args: Array[Variant] = []) -> void:
    pass

