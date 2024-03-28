class_name ContentSelectAdapter
extends EntityAdapter

signal changed(slot: int)

class ContentSelectSlot extends RefCounted:
    var content: Content
    var amount: float

    func load_data(stream: Stream) -> void:
        content = Contents.get_content_by_index(stream.get_64())
        amount = stream.get_double()

    func save_data(stream: Stream) -> void:
        stream.store_64(content.index if content else 0)
        stream.store_double(amount)

@export var slot_size: int = 4
@export var allow_blacklist: bool = false
@export var float_amount: bool = false
var slots: Array[ContentSelectSlot] = []
var blacklist: bool = false

func init_slots(size: int) -> void:
    slots.resize(size)
    for index in size:
        if slots[size] == null:
            slots[size] = ContentSelectSlot.new()

func _ready() -> void:
    if slots.size() != slot_size: init_slots(slot_size)

func _handle_operation(operation: String, args: Array = []) -> void:
    match operation:
        "set_slot": set_slot(args[0], args[1], args[2])
        "set_blacklist": set_blacklist(args[0])
        _: super._handle_operation(operation, args)

func _handle_remote_operation(source: Entity, operation: String, args: Array = []) -> void:
    match operation:
        "set_slot": set_slot(args[0], args[1], args[2])
        "set_blacklist": set_blacklist(args[0])
        "set_slot_from_hand": set_slot_from_hand(args[0], source)
        _: super._handle_remote_operation(source, operation, args)

func set_slot(index: int, content: Content, amount: float) -> void:
    if slot_size <= index or index < 0: return
    slots[index].content = content
    slots[index].amount = amount

func set_slot_from_hand(index: int, entity: Entity) -> void:
    if not entity.has_adapter("inventory"): return
    var inventory = entity.get_adapter("inventory") as Inventory
    var hand = inventory.get_slot(inventory.hand_slot)
    set_slot(index, hand.item_type if hand else null, hand.amount if hand else 0)

func set_blacklist(enable: bool) -> void:
    if not allow_blacklist: return
    blacklist = enable

func has_content(content: Content, found = not blacklist) -> bool:
    for slot in slots:
        if slot.content == content: return found
    return not found

func get_amount(content: Content) -> float:
    var amount = 0
    for slot in slots:
        if slot.content == content: amount += slot.amount
    return amount

func get_amount_int(content: Content) -> int:
    return round(get_amount(content))

func _should_save_data() -> bool:
    return true

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        blacklist = stream.get_8() == 1
        slot_size = stream.get_32()
        init_slots(slot_size)
        for index in slot_size:
            slots[index].load_data(stream)
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_8(1 if blacklist else 0)
        stream.store_32(slot_size)
        for index in slot_size:
            slots[index].save_data(stream)
    ])
