class_name ResourceType
extends Resource

@export var name: String

func _get_type() -> ResourceTypeType:
    return null

func get_type() -> ResourceTypeType:
    return _get_type()

