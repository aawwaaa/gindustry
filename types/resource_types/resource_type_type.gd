class_name ResourceTypeType
extends ResourceType

var types: Dictionary:
    get: return G.types.get_types(self)

func _get_type() -> ResourceTypeType:
    return self
