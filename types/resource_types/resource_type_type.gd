class_name ResourceTypeType
extends ResourceType

var types: Dictionary:
    get: return Types.get_types(self)

func _get_type() -> ResourceTypeType:
    return self
