extends Node

var resource_type_types: Dictionary = {}
var types: Dictionary = {}

func register_type(type: ResourceType) -> void:
    if type is ResourceTypeType:
        resource_type_types[type.name] = type
    if not types.has(type.get_type()):
        types[type.get_type()] = {}
    types[type.get_type()][type.name] = type

func get_types(type: ResourceTypeType) -> Dictionary:
    if not types.has(type):
        types[type] = {}
    return types[type]

func get_type(type: ResourceTypeType, name: String) -> ResourceType:
    return get_types(type)[name] if get_types(type).has(name) else null
