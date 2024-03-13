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

func _on_building_input_operation(operation: String, args: Array) -> void:
    if operation == "open_panel":
        Global.input_handler.call_input_processor("item", "access_target_ui", [self])

func init_inventory_panel(panel: InventoryPanel) -> void:
    panel.interface.inventory = entity.get_adapter("inventory")

