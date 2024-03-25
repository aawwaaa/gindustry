class_name GeneralItemType
extends ItemType

@export var max_stack_amount: int = 100
@export var cost_per_item: float = 1

func _get_max_stack() -> int:
    return max_stack_amount

func _get_cost() -> float:
    return cost_per_item


