class_name RefObjectRef
extends RefCounted

var v: RefObject = null:
    set = set_v
var id: int = 0:
    get = get_id,
    set = set_id

func set_v(value: RefObject) -> void:
    v = value

func get_id() -> int:
    return v.object_id if v else 0

func set_id(value: int) -> void:
    id = value
    v = null
    Vars.objects.get_object_callback(id, func(obj):
        v = obj
    )
