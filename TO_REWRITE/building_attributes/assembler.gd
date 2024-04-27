class_name BuildingAttribute_Assembler
extends BuildingAttribute

const TYPE = preload("res://contents/building_attributes/assembler.tres")

@export var level: int;

func _get_type() -> BuildingAttributeType:
    return TYPE

func _get_level() -> float:
    return level
