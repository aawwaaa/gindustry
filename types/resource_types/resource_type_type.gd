class_name ResourceTypeType
extends "res://types/resource_type.gd"

var types: Dictionary:
    get: return Types.get_types(self)

func _get_type() -> ResourceTypeType:
    return self
