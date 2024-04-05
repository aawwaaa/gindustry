class_name ItemSelectInterface
extends AdapterInterface

static var slot_scene = load("res://ui/adapter_interfaces/ui_item_select_slot.tscn")

var blacklist_toggle: HBoxContainer
var blacklist_enabled: CheckButton
var slots_container: HFlowContainer

var slots: Array[UIItemSelectSlot] = []
var item_select: ItemSelectAdapter:
    get: return adapter as ItemSelectAdapter

func _ready() -> void:
    super._ready()
    create_nodes()
    load_slots()

func create_nodes() -> void:
    blacklist_toggle = HBoxContainer.new()
    blacklist_toggle.size_flags_horizontal = Control.SIZE_FILL
    add_child(blacklist_toggle)

    var whitelist_label = Label.new()
    whitelist_label.text = tr("ContentSelectInterface_Whitelist")
    blacklist_toggle.add_child(whitelist_label)

    blacklist_enabled = CheckButton.new()
    blacklist_enabled.focus_mode = Control.FOCUS_NONE
    blacklist_toggle.add_child(blacklist_enabled)

    var blacklist_label = Label.new()
    blacklist_label.text = tr("ContentSelectInterface_Blacklist")
    blacklist_toggle.add_child(blacklist_label)

    slots_container = HFlowContainer.new()
    slots_container.size_flags_horizontal = Control.SIZE_FILL
    add_child(slots_container)

func _set_adapter(v: EntityAdapter, old: EntityAdapter) -> void:
    Utils.signal_dynamic_connect(v, old, &"item_slot_changed", _on_item_slot_changed)
    Utils.signal_dynamic_connect(v, old, &"blacklist_changed", _on_blacklist_changed)
    if interface_ready: load_slots()

func load_slots() -> void:
    blacklist_toggle.visible = item_select.allow_blacklist if item_select else false
    blacklist_enabled.set_pressed_no_signal(item_select.blacklist if item_select else false)
    slots = []
    for child in slots_container.get_children():
        child.queue_free()
    if not item_select:
        return
    for index in item_select.slot_size:
        var slot = slot_scene.instantiate() as UIItemSelectSlot
        slots_container.add_child(slot)
        slot.slot = index
        slot.update_data(item_select.slots[index])
        slot.pressed.connect(_on_slot_pressed)
        slots.append(slot)

func _on_item_slot_changed(index: int, slot: Item) -> void:
    slots[index].update_data(slot)

func _on_blacklist_changed(blacklist: bool) -> void:
    blacklist_enabled.set_pressed_no_signal(blacklist)

func _on_blacklist_enabled_toggled(toggled_on: bool) -> void:
    operate_adapter("set_blackist", [toggled_on])

func _on_slot_pressed(index: int) -> void:
    if remote_entity:
        var inventory: Inventory = Game.current_entity.get_adapter(Inventory.I_DEFAULT_NAME)
        if inventory.is_slot_has_item(inventory.hand_slot):
            operate_adapter("set_slot_from_hand", [index])
            return
    var slot = item_select.slots[index]
    var result = await GameUI.instance.content_selector.select_content( \
            slot.item_type if item_select.is_slot_has_item(index) else null, 1, false, \
            item_select.filte_content_type)
    if not result: return
    operate_adapter("set_slot", [index, result.content])

