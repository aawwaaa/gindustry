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

@export var hand_slot: int = 0

var slots: Array[Item] = [];

func _handle_operation(operate: String, args: Array = []) -> void:
    match operate:
        "swap_with_hand": swap_with_other_hand(args[0])
        "use_hand": use_hand(args[0], args[1])
        "drop_item": drop_item(args[0], args[1])
        "drop_item_at": drop_item_at(args[0], args[1], args[2])
        _: super._handle_operation(operate, args)

func _handle_remote_operation(source: Entity, operate: String, args: Array = []) -> void:
    match operate:
        "swap_with_hand": swap_with_other_hand(args[0], source.get_adapter("inventory"))
        _: super._handle_remote_operation(source, operate, args)

func _ready() -> void:
    slots_size = slots_size

func _accept_item(item: Item) -> bool:
    return true
    
func _accept_item_amount(item: Item) -> int:
    var amount = 0;
    for slot in slots.size():
        if is_slot_has_item(slot):
            amount += get_slot(slot).get_available_merge_amount(item)
        else:
            amount += item.get_max_stack_amount()

    return amount

func _offer_items() -> Array[Item]:
    var items: Array[Item] = []
    for slot in slots.size():
        if not is_slot_has_item(slot): continue
        items.append(slot)
    return items

func is_slot_has_item(slot: int) -> bool:
    if slot >= slots.size(): return false
    if slots[slot] == null: return false
    if not is_instance_valid(slots[slot]): return false
    return not slots[slot].is_empty()

func get_slot(slot: int) -> Item:
    if not is_slot_has_item(slot):
        return null
    return slots[slot]

func set_slot(slot: int, item: Item) -> void:
    var old = slots[slot]
    if item and item.is_empty(): item = null
    slots[slot] = item
    inventory_slot_changed.emit(slot, old != item)

func update_slot(slot: int) -> void:
    if slots[slot] and slots[slot].is_empty():
        slots[slot] = null
        inventory_slot_changed.emit(slot, true)
        return
    inventory_slot_changed.emit(slot, false)

func use_hand(world: World, position: Vector2) -> void:
    var item = get_slot(hand_slot)
    if not item or not await item._useable(entity_node, world, position):
        return
    var use = item.create_use(entity_node, world)
    use.inventory = self
    use.slot = hand_slot
    use._set_position(position)
    use._use()

func split_dropped_item(type: String = "all") -> Item:
    var item = get_slot(hand_slot)
    var amount = item.amount if type == "all" else \
            ceili(item.amount / 2.0) if type == "half" else \
            1 if type == "one" else 0
    var splited = item.split_to(amount)
    return splited

func merge_overflowed_dropped_item(overflow: Item) -> void:
    if overflow != null:
        var item = get_slot(hand_slot)
        if not item: set_slot(hand_slot, overflow)
        else: item.merge_from(overflow)
    update_slot(hand_slot)

func drop_item(target: Entity, type: String = "all") -> void:
    if not entity_node.request_access_target(target.main_node): return
    var splited = split_dropped_item(type)
    var overflow = target.get_adapter("item").add_item(splited)
    merge_overflowed_dropped_item(overflow)
    entity_node.clear_access_target()

static func create_dropped_item_at(world: World, position: Vector2) -> EntityNode_DroppedItem:
    var tile_pos = Tile.to_tile_pos(position)
    var tile = world.get_tile_or_null(tile_pos)
    if tile.building_ref != 0: return tile.building.main_node \
            if tile.building and tile.building.main_node is EntityNode_DroppedItem \
            else null
    var building = tile.set_building(Contents.get_content_by_id("builtin_building_dropped_item"))
    return building.main_node

func drop_item_at(world: World, position: Vector2, type: String = "all") -> void:
    var dropped_item = create_dropped_item_at(world, position)
    if not dropped_item: return
    drop_item(dropped_item.get_entity(), type)

func swap_with_other_hand(slot: int, other: Inventory = self) -> void:
    if not other.is_slot_has_item(other.hand_slot) or \
            (is_slot_has_item(slot) and not get_slot(slot).is_same_item(other.get_slot(other.hand_slot))):
        if not is_slot_has_item(slot):
            return
        var item = get_slot(slot)
        set_slot(slot, other.get_slot(other.hand_slot))
        other.set_slot(other.hand_slot, item)
        return
    var other_item = other.get_slot(other.hand_slot)
    set_slot(slot, other_item.split_to(other_item.amount, get_slot(slot)))
    other.update_slot(other.hand_slot)

func _add_item(item: Item) -> Item:
    var amount = 0
    for index in slots.size():
        if item.is_empty():
            break
        if hand_slot == index:
            continue
        var last_amount = item.amount
        if not is_slot_has_item(index):
            set_slot(index, item.split_to(Item.INF_AMOUNT))
            inventory_slot_changed.emit(index, true)
        elif get_slot(index).is_same_item(item):
            get_slot(index).merge_from(item)
            update_slot(index)
            inventory_slot_changed.emit(index, false)
        var delta = last_amount - item.amount
        amount += delta
    if amount != 0:
        item_added.emit(item, amount)
    return item

func _remove_item(template: Item, amount: int = template.amount) -> Item:
    var item = template.copy_type();
    for index in slots.size():
        var left = amount - item.amount
        if not is_slot_has_item(index):
            continue
        if item.is_same_item(get_slot(index)):
            get_slot(index).split_to(left, item, true)
            update_slot(index)
    if not item.is_empty():
        item_removed.emit(item, amount)
    return item

func remove_items(templates: Array[Item]) -> Array[Item]:
    var removed_items = []
    for template in templates:
        removed_items.append(remove_item(template))
    return removed_items

func _check_item(template: Item, target_amount = template.amount) -> bool:
    return _get_item_amount(template) >= target_amount

func check_items(templates: Array[Item]) -> bool:
    var passed = true
    for template in templates:
        if not check_item(template):
            passed = false;
            break
    return passed

func _get_item_amount(template: Item) -> int:
    var amount = 0
    for index in slots.size():
        if not is_slot_has_item(index):
            continue
        if template.is_same_item(get_slot(index)):
            amount += get_slot(index).amount
    return amount

func _handle_break(unit: BuilderAdapterUnit) -> bool:
    for slot in slots.size():
        if not is_slot_has_item(slot): continue
        var item = get_slot(slot)
        var item_adapter = unit.adapter.entity_node.get_adapter("item") as ItemAdapter
        set_slot(slot, item_adapter.add_item(item))
        if is_slot_has_item(slot): return false
    return true

func _should_save_data() -> bool:
    return true

const current_data_version = 0;

func _load_data(stream: Stream) -> void:
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

func _save_data(stream: Stream) -> void:
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
 
