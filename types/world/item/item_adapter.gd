class_name ItemAdapter
extends Node

func _accept_item(item: Item) -> bool:
    return false
    
func _accept_item_amount(item: Item) -> int:
    return 0

func _offer_items() -> Array[Item]:
    return []

func _add_item(item: Item) -> Item:
    return item

func _remove_item(template: Item, amount: int = template.amount) -> Item:
    return template._copy_type()

func _check_item(template: Item, target_amount = template.amount) -> bool:
    return false
