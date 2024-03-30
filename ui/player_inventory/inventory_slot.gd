class_name UIInventorySlot
extends Control

signal request_swap(slot: int)

@export var inventory: Inventory
@export var slot: int

func _ready() -> void:
    changed(true)

func changed(item_type_changed: bool) -> void:
    if inventory.is_slot_has_item(slot):
        %Amount.text = str(inventory.slots[slot].amount)
    else:
        %Amount.text = ""
    if not item_type_changed:
        return
    for child in %ItemContainer.get_children():
        %ItemContainer.remove_child(child)
    if inventory.is_slot_has_item(slot):
        var display = inventory.get_slot(slot).create_display()
        display.set_in_inventory(true, inventory)
        %ItemContainer.add_child(display)

func clear_pressed() -> void:
    %Button.button_pressed = false

func _on_button_pressed() -> void:
    request_swap.emit(slot)
