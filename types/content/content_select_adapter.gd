class_name ContentSelectAdapter
extends EntityAdapter

signal content_slot_changed(index: int, slot: ContentSelectSlot)
signal blacklist_changed(enabled: bool)

const DEFAULT_NAME = "cselect"

const CONFIG_KEY = "cselect"
const CONFIG_TARGET_CONTENT_DISPLAY_GROUP = "cdg"
const CONFIG_TARGET_SPRITE2D = "s2d"
const CONFIG_TARGET_SPRITE2D_NODE = "node"
const CONFIG_TARGET_SPRITE2D_WHITELIST_TEXTURE = "wltex"
const CONFIG_TARGET_SPRITE2D_BLACKLIST_TEXTURE = "bltex"

class ConfigHandler extends AdapterConfig.ConfigHandler:
    func _get_type() -> String:
        return CONFIG_KEY
    func _generate_config(uncasted: EntityAdapter) -> Variant:
        var adapter = uncasted as ContentSelectAdapter
        var slots: Array[Array] = []
        for slot in adapter.slots:
            slots.append([slot.content, slot.amount])
        return {
            CKEY_BLACKLIST: adapter.blacklist,
            CKEY_SLOTS: slots
        }
    func _apply_config(config: Variant, type: String, uncasted: EntityAdapter) -> void:
        var adapter = uncasted as ContentSelectAdapter
        adapter.blacklist = config[CKEY_BLACKLIST] if adapter.allow_blacklist else false
        for index in adapter.slots.size():
            var has = config[CKEY_SLOTS].size() > index
            adapter.slots[index].content = config[CKEY_SLOTS][index][0] if has else null
            adapter.slots[index].amount = adapter.format_amount(config[CKEY_SLOTS][index][1]) if has else 0
    func _apply_shadow(config: Variant, type: String, targets: Dictionary) -> void:
        if CONFIG_TARGET_CONTENT_DISPLAY_GROUP in targets:
            var display_group = targets[CONFIG_TARGET_CONTENT_DISPLAY_GROUP] as ContentDisplayGroup
            display_group.datas = config[CKEY_SLOTS]
            display_group.content_getter = get_display_group_data
            display_group.update()
        if CONFIG_TARGET_SPRITE2D in targets:
            var node = targets[CONFIG_TARGET_SPRITE2D][CONFIG_TARGET_SPRITE2D_NODE] as Sprite2D
            var blacklist_texture = targets[CONFIG_TARGET_SPRITE2D][CONFIG_TARGET_SPRITE2D_BLACKLIST_TEXTURE] as Texture2D
            var whitelist_texture = targets[CONFIG_TARGET_SPRITE2D][CONFIG_TARGET_SPRITE2D_WHITELIST_TEXTURE] as Texture2D
            node.texture = blacklist_texture if config[CKEY_BLACKLIST] else whitelist_texture

    func _save_data(config: Variant, stream: Stream) -> void:
        stream.store_8(1 if config[CKEY_BLACKLIST] else 0)
        stream.store_32(config[CKEY_SLOTS].size())
        for slot in config[CKEY_SLOTS]:
            stream.store_64(slot[0].index if slot[0] else 0)
            stream.store_double(slot[1])
    func _load_data(stream: Stream) -> Variant:
        var config = {
            CKEY_BLACKLIST: stream.get_8() == 1,
            CKEY_SLOTS: []
        }
        var size = stream.get_32()
        for index in size:
            var content = Contents.get_content_by_index(stream.get_64())
            var amount = stream.get_double()
            config[CKEY_SLOTS].append([content, amount])
        return config

    static func get_display_group_data(slot: Array) -> Content:
        return slot[0]

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

static func _static_init() -> void:
    var handler = ConfigHandler.new()
    AdapterConfig.register_handler(handler)

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
