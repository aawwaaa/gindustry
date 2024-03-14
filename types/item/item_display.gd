class_name ItemDisplay
extends Node2D

var item: Item;

func _ready() -> void:
    item.data_updated.connect(data_updated)
    data_updated()

func data_updated() -> void:
    %Icon.texture = item.item_type.get_texture()

func _set_in_inventory(in_inventory: bool, inventory: Inventory) -> void:
    pass

func set_in_inventory(in_inventory: bool, inventory: Inventory) -> void:
    _set_in_inventory(in_inventory, inventory)
    data_updated()
