class_name GeneralItemType
extends ItemType

@export var item_texture: Texture2D = load("res://assets/asset-not-found.png")
@export var max_stack_amount: int = 100
@export var cost_per_item: int = 1

func _get_texture() -> Texture2D:
    return item_texture

func _get_max_stack() -> int:
    return max_stack_amount

func _get_cost() -> int:
    return cost_per_item


