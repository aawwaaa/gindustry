class_name BuildingCategory
extends Content

@export var icon: Texture2D

var building_types: Array[BuildingType] = []

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "BuildingCategory")

func _get_content_type() -> String:
    return "building_category"


