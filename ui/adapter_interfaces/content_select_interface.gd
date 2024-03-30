class_name ContentSelectInterface
extends AdapterInterface

static var slot_scene = load("res://ui/adapter_interfaces/ui_content_select_slot.tscn")

@onready var blacklist_toggle: HBoxContainer = %BlacklistToggle
@onready var blacklist_enabled: CheckButton = %BlacklistEnabled
@onready var slots_container: HFlowContainer = %Slots

var slots: Array[UIContentSelectSlot] = []
var content_select: ContentSelectAdapter:
    get: return adapter as ContentSelectAdapter

func _ready() -> void:
    super._ready()
    load_slots()

func _set_adapter(v: EntityAdapter, old: EntityAdapter) -> void:
    Utils.signal_dynamic_connect(v, old, &"content_slot_changed", _on_content_slot_changed)
    Utils.signal_dynamic_connect(v, old, &"blacklist_changed", _on_blacklist_changed)
    if interface_ready: load_slots()

func load_slots() -> void:
    blacklist_toggle.visible = content_select.allow_blacklist if content_select else false
    blacklist_enabled.set_pressed_no_signal(content_select.blacklist if content_select else false)
    slots = []
    for child in slots_container.get_children():
        child.queue_free()
    if not content_select:
        return
    for index in content_select.slot_size:
        var slot = slot_scene.instantiate() as UIContentSelectSlot
        slots_container.add_child(slot)
        slot.slot = index
        slot.update_data(content_select.slots[index])
        slot.pressed.connect(_on_slot_pressed)
        slots.append(slot)

func _on_content_slot_changed(index: int, slot: ContentSelectAdapter.ContentSelectSlot) -> void:
    slots[index].update_data(slot)

func _on_blacklist_changed(blacklist: bool) -> void:
    blacklist_enabled.set_pressed_no_signal(blacklist)

func _on_blacklist_enabled_toggled(toggled_on: bool) -> void:
    operate_adapter("set_blackist", [toggled_on])

func _on_slot_pressed(index: int) -> void:
    if remote_entity:
        var inventory: Inventory = Game.current_entity.get_adapter("inventory")
        if inventory.is_slot_has_item(inventory.hand_slot):
            operate_adapter("set_slot_from_hand", [index])
            return
    var slot = content_select.slots[index]
    var result = await GameUI.instance.content_selector.select_content( \
            slot.content, slot.amount, content_select.get_float_amount(), \
            content_select.filte_content_type)
    if not result: return
    operate_adapter("set_slot", [index, result.content, result.amount])

