class_name ItemAdapter
extends EntityAdapter

func _handle_overflow_item(item: Item) -> void:
    pass

func handle_overflow_item(item: Item) -> void:
    _handle_overflow_item(item)

func _accept_item(item: Item) -> bool:
    return false

func accept_item(item: Item) -> bool:
    return _accept_item(item)
    
func _accept_item_amount(item: Item) -> int:
    return 0

func accept_item_amount(item: Item) -> int:
    return _accept_item_amount(item)

func _offer_items() -> Array[Item]:
    return []

func offer_items() -> Array[Item]:
    return _offer_items()

func _add_item(item: Item) -> Item:
    return item

func add_item(item: Item) -> Item:
    return _add_item(item)

func _remove_item(template: Item, amount: int = template.amount) -> Item:
    return template.copy_type()

func remove_item(template: Item, amount: int = template.amount) -> Item:
    return _remove_item(template, amount)

func _check_item(template: Item, target_amount = template.amount) -> bool:
    return false

func check_item(template: Item, target_amount = template.amount) -> bool:
    return _check_item(template, target_amount)

func _get_item_amount(template: Item) -> int:
    return 0

func get_item_amount(template: Item) -> int:
    return _get_item_amount(template)
