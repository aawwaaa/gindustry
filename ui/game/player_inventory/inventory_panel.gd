class_name InventoryPanel
extends ScrollContainer

var entity: Entity:
    set = set_entity;

signal request_operation(operation: String, args: Array[Variant])
signal request_remote_operation(operation: String, args: Array[Variant])

func set_entity(v: Entity) -> void:
    entity = v


