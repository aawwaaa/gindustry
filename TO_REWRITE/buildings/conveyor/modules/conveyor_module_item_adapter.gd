extends ItemAdapter

var module: EntityNode_ConveyorModule:
    get: return main_node as EntityNode_ConveyorModule

func _offer_items() -> Array[Item]:
    return module.get_tracks().reduce(func(items, track):
        return items + track.items.map(func(item): return item.item), [])

func _remove_item(template: Item, amount: int = template.amount) -> Item:
    var out = template.copy_type()
    for track in module.get_tracks():
        for item in track.items:
            if not out.is_same_item(item.item): continue
            item.item.split_to(amount - out.amount, out)
            if item.item.is_empty(): item.remove()
    return out

func _check_item(template: Item, target_amount = template.amount) -> bool:
    return _get_item_amount(template) >= target_amount

func _get_item_amount(template: Item) -> int:
    var amount = 0
    for track in module.get_tracks():
        for item in track.items:
            if not template.is_same_item(item.item): continue
            amount += item.item.amount
    return amount


