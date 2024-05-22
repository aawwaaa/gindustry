class_name GDScriptObjectType
extends ObjectType

@export var type_script: GDScript

func _create() -> RefObject:
    return type_script.new()
