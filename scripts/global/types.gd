class_name G_Types
extends G.G_Object

var log_source = Log.register_log_source("types")

var resource_type_types: Dictionary = {}
var types: Dictionary = {}

func register_type(type: ResourceType) -> void:
    log_source.debug("Load type: " + str(type.get_type().name, " ", type.name))
    type.mod = Contents.current_loading_mod
    if type is ResourceTypeType:
        resource_type_types[type.name] = type
        if not types.has(type):
            types[type] = {}
        return
    if not types.has(type.get_type()):
        types[type.get_type()] = {}
    types[type.get_type()][type.name] = type

func get_types(type: ResourceTypeType) -> Dictionary:
    if not types.has(type):
        types[type] = {}
    return types[type]

func get_type(type: ResourceTypeType, name: String) -> ResourceType:
    return get_types(type)[name] if get_types(type).has(name) else null
