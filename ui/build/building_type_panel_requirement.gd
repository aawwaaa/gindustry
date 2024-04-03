class_name BuildingTypePanel_Requirement
extends HBoxContainer

@export var enough_item_style: LabelSettings
@export var missing_item_style: LabelSettings

@onready var item_container: Control = %ItemContainer
@onready var item_name: Label = %Name
@onready var item_amount: Label = %Amount
@onready var item_required: Label = %Required

func apply_data(item: Item, amount: int, required: int, use_style = true) -> void:
    for child in item_container.get_children():
        child.queue_free()
    if not item:
        visible = false
        return
    visible = true
    var display = item.create_display()
    item_container.add_child(display)
    item_name.text = item.get_localized_name()
    item_amount.text = str(amount)
    item_required.text = str(required)
    item_amount.label_settings = null if not use_style \
            else enough_item_style if amount >= required \
            else missing_item_style
