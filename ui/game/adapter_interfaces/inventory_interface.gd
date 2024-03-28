class_name InventoryInterface
extends AdapterInterface

static var ui_inventory_slot = load("res://ui/game/player_inventory/inventory_slot.tscn")

var inventory: Inventory:
    get: return adapter as Inventory
var slots_nodes: Array[UIInventorySlot] = []
var slots_container: HFlowContainer

func _ready() -> void:
    super._ready()
    slots_container = HFlowContainer.new()
    add_child(slots_container)
    load_inventory()

func _set_adapter(v: EntityAdapter, old: EntityAdapter) -> void:
    if old:
        old.inventory_slot_changed.disconnect(_on_inventory_slot_changed)
    if inventory:
        inventory.inventory_slot_changed.connect(_on_inventory_slot_changed)
    if interface_ready: load_inventory()

func load_inventory() -> void:
    slots_nodes = []
    for child in slots_container.get_children():
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
        slots_container.add_child(slot)

func _on_slot_request_swap(slot: int) -> void:
    operate_adapter("swap_with_hand", [slot])

func _on_inventory_slot_changed(slot_id: int, item_type_changed: bool) -> void:
    slots_nodes[slot_id].changed(item_type_changed)
