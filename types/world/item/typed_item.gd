class_name TypedItem
extends ItemType

@export var target: ItemType

func create_item() -> Item:
    var item = target.create_item()
    item.apply_type(self)
    return item

func get_tr_name() -> String:
    return target.get_tr_name()

func _get_item_scene() -> PackedScene:
    return target.item_scene

func _get_use_scene() -> PackedScene:
    return target.use_scene

func _get_texture() -> Texture2D:
    return target.texture

func _get_max_stack() -> int:
    return target.max_stack

func _get_cost() -> int:
    return target.cost

