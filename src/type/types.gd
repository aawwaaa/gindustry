class_name Vars_Types
extends Vars.Vars_Object

var logger = Log.register_logger("Types_LogSource")

var resource_type_types: Dictionary = {}
var types: Dictionary = {}

func register_type(type: ResourceType) -> ResourceType:
    type.mod = Vars.mods.current_loading_mod
    type._data()
    type.mod.types.append(type)
    type.init_full_id();
    logger.debug("Load type: " + type.full_id)
    if type is ResourceTypeType:
        resource_type_types[type.full_id] = type
        if not types.has(type):
            types[type] = {}
    else:
        if not types.has(type.get_type()):
            types[type.get_type()] = {}
        types[type.get_type()][type.full_id] = type
    type._type_registed()
    type._assign()
    return type

func get_types(type: ResourceTypeType) -> Dictionary:
    if not types.has(type):
        types[type] = {}
    return types[type]

func get_type(type: ResourceTypeType, n: String) -> ResourceType:
    return get_types(type)[n] if get_types(type).has(n) else null

func get_type_type(n: String) -> ResourceTypeType:
    return resource_type_types[n]
