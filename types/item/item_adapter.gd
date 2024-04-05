class_name ItemAdapter
extends EntityAdapter

const DEFAULT_NAME = "item"

@export var item_targets: Array[ItemAdapter] = []

func _handle_overflow_item(item: Item) -> void:
    pass

func handle_overflow_item(item: Item) -> void:
    _handle_overflow_item(item)

func _accept_item(item: Item) -> bool:
    return false

func accept_item(item: Item) -> bool:
    if _accept_item(item): return true
    for target in item_targets:
        if target.accept_item(item): return true
    return false
    
func _accept_item_amount(item: Item) -> int:
    return 0

func accept_item_amount(item: Item) -> int:
    if not accept_item(item): return 0
    var amount = _accept_item_amount(item)
    if amount != 0: return amount
    for target in item_targets:
        amount = target.accept_item_amount(item)
        if amount != 0: return amount
    return 0

func _offer_items() -> Array[Item]:
    return []

func offer_items() -> Array[Item]:
    return _offer_items()

func _add_item(item: Item) -> Item:
    return item

func add_item(item: Item) -> Item:
    var left = _add_item(item)
    if left.is_empty(): return left
    for target in item_targets:
        left = target.add_item(item)
        if left.is_empty(): return left
    return left

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
