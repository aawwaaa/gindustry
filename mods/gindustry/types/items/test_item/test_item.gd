class_name Gindustry_TestItem
extends GeneralItemType

const USE_SCENE = preload("res://mods/gindustry/types/items/test_item/test_item_use.tscn")

@export var floor_type: Floor;

func _get_use_scene() -> PackedScene:
    return USE_SCENE
