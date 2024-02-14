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
        child._set_in_inventory(false, inventory)
        %ItemContainer.remove_child(child)
    if inventory.is_slot_has_item(slot):
        inventory.slots[slot]._set_in_inventory(true, inventory)
        %ItemContainer.add_child(inventory.slots[slot])

func clear_pressed() -> void:
    %Button.button_pressed = false

func _exit_tree() -> void:
    if is_instance_valid(inventory) and inventory.is_slot_has_item(slot):
        inventory.slots[slot]._set_in_inventory(false, inventory)

func _on_button_pressed() -> void:
    request_swap.emit(slot)
