class_name TypedItemStack
extends Resource

@export var item_type_id: String;
@export var amount: int
@export var args: Dictionary = {}

var item: Item

func get_item() -> Item:
    if not item:
        var item_type = Contents.get_content_by_id(item_type_id)
        item = item_type.create_item()
        item._apply_type(self)

    return item
