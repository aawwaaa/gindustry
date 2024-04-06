class_name PackedItemStack
extends Resource

@export var item_type: ItemType;
@export var amount: int
@export var options: Dictionary = {}

var item: Item

func get_item() -> Item:
    if not item:
        item = item_type.create_item()
        item.apply_stack(self)

    return item

func create_item() -> Item:
    var item = item_type.create_item()
    item.apply_stack(self)
    return item
