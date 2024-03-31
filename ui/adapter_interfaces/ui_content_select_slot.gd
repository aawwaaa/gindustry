class_name UIContentSelectSlot
extends Control

signal pressed(slot: int)

@onready var button: Button = %Button
@onready var icon: TextureRect = %Icon
@onready var amount: Label = %Amount

var slot: int = 0;

func update_data(slot: ContentSelectAdapter.ContentSelectSlot) -> void:
    icon.texture = slot.content.get_icon() if slot.content else null
    self.amount.text = str(slot.amount)

func _on_button_pressed() -> void:
    pressed.emit(slot)

