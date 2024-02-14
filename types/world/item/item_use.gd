class_name ItemUse
extends Node2D

var item: Item
var item_type: ItemType:
    get: return item.item_type
    set(v): return;

var inventory: Inventory
var slot: int

var world: World
var user: Entity

func _set_position(position: Vector2):
    self.position = position

func _use() -> void:
    queue_free()

func remove_items(amount: int) -> Item:
    var removed = item._split_to(amount)
    inventory.inventory_slot_changed.emit(slot, true)
    return removed
