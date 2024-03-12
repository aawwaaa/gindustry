class_name EntityNode_DroppedItem
extends Node2D

@export var entity: Building;
@onready var inventory: Inventory = $Inventory

func get_entity() -> Entity:
    return entity

func _on_inventory_inventory_slot_changed(slot_id: int, item_type_changed: bool) -> void:
    for slot in inventory.slots.size():
        if inventory.is_slot_has_item(slot): return
    entity.world.get_tile_or_null(entity.pos).clear_building.call_deferred()

