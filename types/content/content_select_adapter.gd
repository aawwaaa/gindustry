class_name ContentSelectAdapter
extends EntityAdapter

signal content_slot_changed(index: int, slot: ContentSelectSlot)
signal blacklist_changed(enabled: bool)

class ContentSelectSlot extends RefCounted:
    var content: Content
    var amount: float

    func load_data(stream: Stream) -> void:
        content = Contents.get_content_by_index(stream.get_64())
        amount = stream.get_double()

    func save_data(stream: Stream) -> void:
        stream.store_64(content.index if content else 0)
        stream.store_double(amount)

    static func get_content(slot: ContentSelectSlot) -> Content:
        return slot.content if slot.amount != 0 else null

@export var slot_size: int = 4
@export var allow_blacklist: bool = false
@export var allow_float_amount: bool = false
var slots: Array[ContentSelectSlot] = []
var blacklist: bool = false

@export var content_display_group: ContentDisplayGroup

func init_slots(size: int) -> void:
    slots.resize(size)
    for index in size:
        if slots[index] == null:
            slots[index] = ContentSelectSlot.new()

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

func update_display_group() -> void:
    if not content_display_group: return
    if content_display_group.datas != slots:
        content_display_group.datas = slots
        content_display_group.content_getter = ContentSelectSlot.get_content
    content_display_group.update()

func set_slot(index: int, content: Content, amount: float) -> void:
    if slot_size <= index or index < 0: return
    if content and not filte_content_type(content.get_content_type()): return
    slots[index].content = content
    slots[index].amount = amount
    content_slot_changed.emit(index, slots[index])
    update_display_group()

func set_slot_from_hand(index: int, entity: Entity) -> void:
    if not entity.has_adapter(Inventory.I_DEFAULT_NAME): return
    var inventory = entity.get_adapter(Inventory.I_DEFAULT_NAME) as Inventory
    var hand = inventory.get_slot(inventory.hand_slot)
    set_slot(index, hand.item_type if hand else null, hand.amount if hand else 0)

func set_blacklist(enable: bool) -> void:
    if not allow_blacklist: return
    blacklist = enable
    blacklist_changed.emit(enable)

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

func filte_content_type(content_type: ContentType) -> bool:
    return true

func get_allow_float_amount() -> bool:
    return allow_float_amount

func format_amount(amount: float) -> float:
    return amount if get_allow_float_amount() else roundf(amount)

func get_config() -> Array[Array]:
    var config = []
    for index in slot_size:
        config.append([slots[index].content, slots[index].amount])
    return config

func set_config(config: Array[Array]) -> void:
    for index in slot_size:
        if index >= config.size():
            set_slot(index, null, 0)
            continue
        var amount = format_amount(config[index][1])
        set_slot(index, config[index][0], amount)

static func apply_config_to_display_group(config: Array[Array], content_display_group: ContentDisplayGroup) -> void:
    content_display_group.datas = config
    content_display_group.content_getter = get_content_from_config
    content_display_group.update()

static func get_content_from_config(config: Array) -> Content:
    return config[0]

static func save_config(config: Array[Array], stream: Stream) -> void:
    stream.store_32(config.size())
    for content in config:
        stream.store_64(content[0].index if content[0] else 0)
        stream.store_double(content[1])

static func load_config(stream: Stream) -> Array[Array]:
    var config = []
    var size = stream.get_32()
    for index in size:
        var content = Contents.get_content_by_index(stream.get_64())
        var amount = stream.get_double()
        config.append([content, amount])
    return config

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
