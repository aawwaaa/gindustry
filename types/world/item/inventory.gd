class_name Inventory
extends ItemAdapter

signal item_added(item: Item, amount: int)
signal item_removed(item: Item, amount: int)
signal inventory_slot_changed(slot_id: int, item_type_changed: bool)

@export var slots_size: int = 8:
    set(v):
        slots_size = v
        if slots.size() != slots_size:
            slots.resize(slots_size)
@export var entity: Entity;

var hand_slot: int = 0

var slots: Array[Item] = []

func handle_operation(operate: String, args: Array) -> void:
    match operate:
        "swap_with_hand":
            var slot: int = args[0]
            swap_with_other_hand(slot)
        "use_hand":
            var world: World = args[0]
            var position: Vector2 = args[1]
            var item = get_slot(hand_slot)
            if not item or not await item._useable(entity, world, position):
                return
            var use = item._create_use(entity, world)
            use.inventory = self
            use.slot = hand_slot
            use._set_position(position)
            use._use()


func handle_remote_operation(source: Entity, operate: String, args: Array) -> void:
    match operate:
        "swap_with_other_hand":
            var slot: int = args[0]
            swap_with_other_hand(slot, source.get_adapter("inventory"))

func _ready() -> void:
    slots_size = slots_size

func _accept_item(item: Item) -> bool:
    return true
    
func _accept_item_amount(item: Item) -> int:
    return Item.INF_AMOUNT

func _offer_items() -> Array[Item]:
    return slots.filter(func(item): return item != null and not item._is_empty())

func is_slot_has_item(slot: int) -> bool:
    if slot >= slots.size(): return false
    if slots[slot] == null: return false
    if not is_instance_valid(slots[slot]): return false
    return not slots[slot]._is_empty()

func get_slot(slot: int) -> Item:
    if not is_slot_has_item(slot):
        return null
    return slots[slot]

func swap_with_other_hand(slot: int, other: Inventory = self) -> void:
    if not other.is_slot_has_item(other.hand_slot) or \
            (is_slot_has_item(slot) and not slots[slot]._is_same_item(other.slots[other.hand_slot])):
        if not is_slot_has_item(slot):
            return
        var item = get_slot(slot)
        slots[slot] = null
        inventory_slot_changed.emit(slot, true)
        slots[slot] = other.get_slot(other.hand_slot)
        other.slots[other.hand_slot] = item
        other.inventory_slot_changed.emit(other.hand_slot, true)
        inventory_slot_changed.emit(slot, true)
        return
    var other_item = other.get_slot(other.hand_slot)
    slots[slot] = other_item._split_to(other_item.amount, get_slot(slot))
    other.inventory_slot_changed.emit(other.hand_slot, true)
    inventory_slot_changed.emit(slot, true)

func _add_item(item: Item) -> Item:
    var amount = 0
    for index in slots.size():
        if item._is_empty():
            break
        if hand_slot == index:
            continue
        var last_amount = item.amount
        if not is_slot_has_item(index):
            slots[index] = item._split_to(Item.INF_AMOUNT)
            inventory_slot_changed.emit(index, true)
        elif slots[index]._is_same_item(item):
            slots[index]._merge_from(item)
            inventory_slot_changed.emit(index, false)
        var delta = last_amount - item.amount
        amount += delta
    if amount != 0:
        item_added.emit(item, amount)
    return item

func _remove_item(template: Item, amount: int = template.amount) -> Item:
    var item = template._copy_type();
    for index in slots.size():
        var left = amount - item.amount
        if not is_slot_has_item(index):
            continue
        if item._is_same_item(slots[index]):
            slots[index]._split_to(left, item, true)
            inventory_slot_changed.emit(index, slots[index]._is_empty())
    if not item._is_empty():
        item_removed.emit(item, amount)
    return item

func remove_items(templates: Array[Item]) -> Array[Item]:
    var removed_items = []
    for template in templates:
        removed_items.append(_remove_item(template))
    return removed_items

func _check_item(template: Item, target_amount = template.amount) -> bool:
    var amount = 0;
    for index in slots.size():
        if not is_slot_has_item(index):
            continue
        if template._is_same_item(slots[index]):
            amount += slots[index].amount
    return amount >= target_amount

func check_items(templates: Array[Item]) -> bool:
    var passed = true
    for template in templates:
        if not _check_item(template):
            passed = false;
            break
    return passed

const current_data_version = 0;

func load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return
    slots_size = stream.get_32()
    hand_slot = stream.get_32()
    slots.resize(slots_size)
    for index in range(slots_size):
        var has_item = stream.get_8() == 1
        if has_item:
            slots[index] = Item.load_from(stream)
            continue
        slots[index] = null

func save_data(stream: Stream) -> void:
    stream.store_16(current_data_version);
    # version 0
    stream.store_32(slots_size)
    stream.store_32(hand_slot)
    for index in range(slots_size):
        if not is_slot_has_item(index):
            stream.store_8(0)
            continue
        stream.store_8(1)
        get_slot(index).save_to(stream)
 
