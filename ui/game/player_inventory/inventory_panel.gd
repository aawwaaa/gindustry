class_name InventoryPanel
extends ScrollContainer

var entity: Entity:
    set = set_entity;
var main_node: Node2D

signal request_operation(operation: String, args: Array[Variant])
signal request_remote_operation(operation: String, args: Array[Variant])

func set_entity(v: Entity) -> void:
    entity = v

func handle_request_swap(inventory: Inventory, slot: int) -> void: 
    request_remote_operation.emit("adapter", ["inventory", "swap_with_other_hand", slot])
