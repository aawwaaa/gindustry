extends ItemAdapter

var conveyor: EntityNode_Conveyor:
    get: return main_node as EntityNode_Conveyor

func _offer_items() -> Array[Item]:
    var left_items = conveyor.track.left_track.items.map(func(item): return item.item)
    var right_items = conveyor.track.right_track.items.map(func(item): return item.item)
    return left_items + right_items

func _remove_item(template: Item, amount: int = template.amount) -> Item:
    var out = template.copy_type()
    for item in conveyor.track.left_track.items:
        if not out.is_same_item(item.item): continue
        item.item.split_to(amount - out.amount, out)
        if item.item.is_empty(): item.remove()
    for item in conveyor.track.right_track.items:
        if not out.is_same_item(item.item): continue
        item.item.split_to(amount - out.amount, out)
        if item.item.is_empty(): item.remove()
    return out

func _check_item(template: Item, target_amount = template.amount) -> bool:
    return _get_item_amount(template) >= target_amount

func _get_item_amount(template: Item) -> int:
    var amount = 0
    for item in conveyor.track.left_track.items:
        if not template.is_same_item(item.item): continue
        amount += item.item.amount
    for item in conveyor.track.right_track.items:
        if not template.is_same_item(item.item): continue
        amount += item.item.amount
    return amount

