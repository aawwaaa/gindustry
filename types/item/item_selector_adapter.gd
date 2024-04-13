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
    if not entity.has_adapter(Inventory.I_DEFAULT_NAME): return
    var inventory = entity.get_adapter(Inventory.I_DEFAULT_NAME) as Inventory
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

func get_config() -> Array[Array]:
    var config = []
    for index in slot_size:
        if not is_slot_has_item(index):
            config.append([null, 0, null])
            continue
        var type = slots[index].item_type
        config.append([type, 1, slots[index]])
    return config

func set_config(config: Array[Array]) -> void:
    for index in slot_size:
        if index >= config.size():
            set_slot(index, null)
            continue
        if config[index].size() < 3:
            set_slot(index, config[index][0])
            continue
        set_slot(index, config[index][0], config[index][2])

static func apply_config_to_display_group(config: Array[Array], content_display_group: ContentDisplayGroup) -> void:
    content_display_group.datas = config
    content_display_group.content_getter = get_content_from_config
    content_display_group.update()

static func get_content_from_config(config: Array) -> Content:
    return config[0]

static func save_config(config: Array[Array], stream: Stream) -> void:
    stream.store_32(config.size())
    for content in config:
        stream.store_8(1 if content[0] else 0)
        if content.size() >= 3 and content[2]:
            content[2].save_to(stream)

static func load_config(stream: Stream) -> Array[Array]:
    var config = []
    var size = stream.get_32()
    for index in size:
        if not stream.get_8():
            config.append([null, 0, null])
            continue
        var item = Item.load_from(stream)
        config.append([item.item_type, 1, item])
    return config

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
