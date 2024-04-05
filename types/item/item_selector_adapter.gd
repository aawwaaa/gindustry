class_name ItemSelectAdapter
extends EntityAdapter

signal item_slot_changed(index: int, slot: Item)
signal blacklist_changed(enabled: bool)

@export var slot_size: int = 4
@export var allow_blacklist: bool = false

@export var content_display_group: ContentDisplayGroup

var slots: Array[Item] = []
var blacklist: bool = false

func init_slots(size: int) -> void:
    slots.resize(size)

func _ready() -> void:
    if slots.size() != slot_size: init_slots(slot_size)

func _handle_operation(operation: String, args: Array = []) -> void:
    match operation:
        "set_slot": set_slot(args[0], args[1])
        "set_blacklist": set_blacklist(args[0])
        _: super._handle_operation(operation, args)

func _handle_remote_operation(source: Entity, operation: String, args: Array = []) -> void:
    match operation:
        "set_slot": set_slot(args[0], args[1])
        "set_blacklist": set_blacklist(args[0])
        "set_slot_from_hand": set_slot_from_hand(args[0], source)
        _: super._handle_remote_operation(source, operation, args)

func update_display_group() -> void:
    if not content_display_group: return
    if content_display_group.datas != slots:
        content_display_group.content_getter = ItemType.get_content.bind(true)
        content_display_group.datas = slots
    content_display_group.update()

func set_slot(index: int, type: ItemType, item: Item = null) -> void:
    if slot_size <= index or index < 0: return
    slots[index] = item if item else type.create_item() if type else null
    if slots[index]: slots[index].amount = 1
    item_slot_changed.emit(index, slots[index])
    update_display_group()

func set_slot_from_hand(index: int, entity: Entity) -> void:
    if not entity.has_adapter(Inventory.DEFAULT_NAME): return
    var inventory = entity.get_adapter(Inventory.DEFAULT_NAME) as Inventory
    var hand = inventory.get_slot(inventory.hand_slot)
    set_slot(index, hand.item_type, hand.copy_type())

func is_slot_has_item(slot: int) -> bool:
    return slots[slot] != null and not slots[slot].is_empty()

func set_blacklist(enable: bool) -> void:
    if not allow_blacklist: return
    blacklist = enable
    blacklist_changed.emit(enable)

func has_content(content: Content, found = not blacklist) -> bool:
    for slot in slot_size:
        if not is_slot_has_item(slot):
            if content == null: return found
            continue
        if slots[slot].item_type == content: return found
    return not found

func get_amount(content: Content) -> float:
    return 0

func get_amount_int(content: Content) -> int:
    return round(get_amount(content))

func filte_content_type(content_type: ContentType) -> bool:
    return content_type == ItemType.ITEM_TYPE

func get_allow_float_amount() -> bool:
    return false

func format_amount(amount: float) -> float:
    return 1

func _should_save_data() -> bool:
    return true

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        blacklist = stream.get_8() == 1
        slot_size = stream.get_32()
        init_slots(slot_size)
        for index in slot_size:
            if not stream.get_8(): continue
            slots[index] = Item.load_from(stream)
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_8(1 if blacklist else 0)
        stream.store_32(slot_size)
        for index in slot_size:
            if not slots[index]:
                stream.store_8(0)
                continue
            stream.store_8(1)
            slots[index].save_to(stream)
    ])
