class_name ItemSelectAdapter
extends EntityAdapter

signal item_slot_changed(index: int, slot: Item)
signal blacklist_changed(enabled: bool)

const DEFAULT_NAME = "iselect"

const CONFIG_KEY = "iselect"
const CONFIG_TARGET_CONTENT_DISPLAY_GROUP = "cdg"
const CONFIG_TARGET_SPRITE2D = "s2d"
const CONFIG_TARGET_SPRITE2D_NODE = "node"
const CONFIG_TARGET_SPRITE2D_WHITELIST_TEXTURE = "wltex"
const CONFIG_TARGET_SPRITE2D_BLACKLIST_TEXTURE = "bltex"

class ConfigHandler extends AdapterConfig.ConfigHandler:
    func _get_type() -> String:
        return CONFIG_KEY
    func _get_applicatablity(type: String, config: Variant) -> int:
        if type == ContentSelectAdapter.CONFIG_KEY: return NORMAL_CONVERTABLE
        return UNAPPLICATABLE
    func _get_convertablity(target: String, config: Variant) -> int:
        if target == ContentSelectAdapter.CONFIG_KEY: return NORMAL_CONVERTABLE
        return UNCONVERTABLE

    func _generate_config(uncasted: EntityAdapter) -> Variant:
        var adapter = uncasted as ItemSelectAdapter
        var slots: Array[Array] = []
        for slot in adapter.slot_size:
            slots.append(adapter.get_slot(slot))
        return {
            CKEY_BLACKLIST: adapter.blacklist,
            CKEY_SLOTS: slots
        }
    func _apply_config(config: Variant, type: String, uncasted: EntityAdapter) -> void:
        var adapter = uncasted as ItemSelectAdapter
        adapter.blacklist = config[CKEY_BLACKLIST] if adapter.allow_blacklist else false
        for index in adapter.slots.size():
            var has = config[CKEY_SLOTS].size() > index
            if type == ContentSelectAdapter.CONFIG_KEY:
                adapter.set_slot(index, config[CKEY_SLOTS][index][0] if has else null)
            elif type == CONFIG_KEY:
                adapter.set_slot(index, null, config[CKEY_SLOTS][index] if has else null)
    func _apply_shadow(config: Variant, type: String, targets: Dictionary) -> void:
        if CONFIG_TARGET_CONTENT_DISPLAY_GROUP in targets:
            var display_group = targets[CONFIG_TARGET_CONTENT_DISPLAY_GROUP] as ContentDisplayGroup
            display_group.datas = config[CKEY_SLOTS]
            display_group.content_getter = get_display_group_data if type == CONFIG_KEY else \
                    get_display_group_data_content if type == ContentSelectAdapter.CONFIG_KEY else null
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
            stream.store_8(1 if slot else null)
            if slot: slot.save_to(stream)
    func _load_data(stream: Stream) -> Variant:
        var config = {
            CKEY_BLACKLIST: stream.get_8() == 1,
            CKEY_SLOTS: []
        }
        var size = stream.get_32()
        for index in size:
            if not stream.get_8(): continue
            config[CKEY_SLOTS].append(Item.load_from(stream))
        return config

    func _convert(target: String, config: Variant) -> Variant:
        if target == ContentSelectAdapter.CONFIG_KEY:
            var new_slots = []
            for slot in config[CKEY_SLOTS]:
                new_slots.append([slot.item_type if slot else null, 1 if slot else 0])
            return {
                CKEY_BLACKLIST: config[CKEY_BLACKLIST],
                CKEY_SLOTS: new_slots
            }
        return null

    static func get_display_group_data(slot: Item) -> Content:
        return slot.item_type if slot else null
 
    static func get_display_group_data_content(slot: Array) -> Content:
        return slot[0]

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

func has_item(item: Item, found = not blacklist) -> bool:
    for slot in slot_size:
        if not is_slot_has_item(slot):
            if item == null: return found
            continue
        if item.is_same_item(slots[slot]): return found
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
