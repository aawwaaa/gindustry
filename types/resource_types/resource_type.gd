class_name ResourceType
extends Resource

@export var name: String

func _get_type() -> ResourceType:
    return null

func get_type() -> ResourceType:
    return _get_type()

