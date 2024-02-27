class_name BuildingCategory
extends ResourceType

const TYPE = preload("res://contents/resource_type_types/building_category.tres")

@export var order: int = 0
@export var icon: Texture2D = load("res://assets/asset-not-found.png")

var building_types: Array[BuildingType] = []

func _get_type() -> ResourceTypeType:
    return TYPE

