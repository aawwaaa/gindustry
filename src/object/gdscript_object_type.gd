class_name GDScriptObjectType
extends GA_ObjectType

@export var type_script: GDScript;

func _create() -> Object:
    if not type_script: return null
    return type_script.new()


