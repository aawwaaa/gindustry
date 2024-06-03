class_name GDScriptObjectType
extends ObjectType

@export var type_script: GDScript:
    set(v): type_script = v; v.set_meta(RefObject.OBJECT_TYPE_META, self)

func _create() -> RefObject:
    if not type_script: return null
    return type_script.new()
