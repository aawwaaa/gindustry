class_name EntityNode_DroppedItem
extends Node2D

@export var entity: Building;
@onready var inventory: Inventory = $Inventory

func get_entity() -> Entity:
    return entity

func _on_inventory_inventory_slot_changed(slot_id: int, item_type_changed: bool) -> void:
    update_display(slot_id, item_type_changed)
    for slot in inventory.slots.size():
        if inventory.is_slot_has_item(slot): return
    entity.world.get_tile_or_null(entity.pos).clear_building.call_deferred()

func update_display(slot_id: int, item_type_changed: bool) -> void:
    if not item_type_changed: return
    var marker = entity.shadow.item_icons.get_child(slot_id) as Marker2D
    for child in marker.get_children():
        child.queue_free()
    if inventory.is_slot_has_item(slot_id):
        var item = inventory.get_slot(slot_id)
        marker.add_child(item.create_display())

func _on_building_input_operation(operation: String, args: Array) -> void:
    if operation == "open_panel":
        Global.input_handler.call_input_processor("item", "access_target_ui", [self])
    if operation == "drop_item":
        Global.input_handler.call_input_processor("item", "accept_drop_item", [self, args])

func get_adapter_at(pos: Vector2i, type: String) -> EntityAdapter:
    if pos != Vector2i.ZERO or type != "item": return null
    return entity.adapters["item"]

