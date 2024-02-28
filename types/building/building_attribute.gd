class_name BuildingAttribute
extends Resource

func _get_type() -> BuildingAttributeType:
    return null

func get_type() -> BuildingAttributeType:
    return _get_type()

func _get_level() -> float:
    return 0

func get_level() -> float:
    return _get_level()
