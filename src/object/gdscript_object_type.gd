class_name GDScriptObjectType
extends ObjectType

@export var type_script: GDScript

func _create() -> RefObject:
    return type_script.new()

static func add(type_id: String, script: GDScript) -> GDScriptObjectType:
    for type in Vars_Objects.objects_reg.object_types_list:
        if type.id == type_id and type is GDScriptObjectType and type.type_script == null:
            type.type_script = script
            return
    var object_type = GDScriptObjectType.new()
    object_type.id = type_id
    object_type.type_script = script
    Vars_Objects.add_object_type(object_type)
    return object_type
