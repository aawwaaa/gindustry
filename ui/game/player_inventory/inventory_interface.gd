class_name UIInventoryInterface
extends HFlowContainer

signal request_swap(inventory: Inventory, slot: int)

static var ui_inventory_slot = load("res://ui/game/player_inventory/inventory_slot.tscn")

@export var inventory: Inventory:
    set(v):
        if inventory:
            inventory.inventory_slot_changed.disconnect(_on_inventory_slot_changed)
        inventory = v
        if inventory:
            inventory.inventory_slot_changed.connect(_on_inventory_slot_changed)

var slots_nodes: Array[UIInventorySlot] = []

func load_inventory() -> void:
    slots_nodes = []
    for child in get_children():
        child.queue_free()
    if not inventory:
        return
    slots_nodes.resize(inventory.slots_size)
    for index in inventory.slots_size:
        var slot = ui_inventory_slot.instantiate()
        slot.inventory = inventory
        slot.slot = index;
        slots_nodes[index] = slot
        slot.request_swap.connect(_on_slot_request_swap)
        add_child(slot)

func _on_slot_request_swap(slot: int) -> void:
    request_swap.emit(inventory, slot)

func _on_inventory_slot_changed(slot_id: int, item_type_changed: bool) -> void:
    slots_nodes[slot_id].changed(item_type_changed)
