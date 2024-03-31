class_name UIItemSelectSlot
extends Control

signal pressed(slot: int)

@onready var button: Button = %Button
@onready var item_container: Control = %ItemContainer

var slot: int = 0;

func update_data(slot: Item) -> void:
    for child in item_container.get_children():
        child.queue_free()
    if not slot or slot.is_empty(): return
    var display = slot.create_display()
    item_container.add_child(display)

func _on_button_pressed() -> void:
    pressed.emit(slot)

