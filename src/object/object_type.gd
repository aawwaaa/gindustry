class_name ObjectType
extends Resource

@export var id: String;
var full_id: String:
    get: return id
var index: int

func _create() -> RefObject:
    return null

func create(no_create: bool = false) -> RefObject:
    var obj = _create()
    if obj: obj.object_type = self
    if obj and not no_create: obj.handle_create()
    return obj
