extends ItemAdapter

var conveyor: EntityNode_Conveyor:
    get: return main_node as EntityNode_Conveyor

func _handle_overflow_item(item: Item) -> void:
    pass

func _accept_item(item: Item) -> bool:
    return false

func _accept_item_amount(item: Item) -> int:
    return 0

func _offer_items() -> Array[Item]:
    return []

func _add_item(item: Item) -> Item:
    return item

func _remove_item(template: Item, amount: int = template.amount) -> Item:
    return template.copy_type()

func _check_item(template: Item, target_amount = template.amount) -> bool:
    return false

func _get_item_amount(template: Item) -> int:
    return 0

