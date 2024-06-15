class_name ContentRef
extends RefCounted

var v: Content = null:
    set = set_v
var full_id: String:
    get = get_full_id,
    set = set_full_id

func set_v(value: Content) -> void:
    v = value

func get_full_id() -> String:
    return v.full_id if v else ""

func set_full_id(value: String) -> void:
    full_id = value
    if value == "":
        v = null
        return
    v = Vars.contents.get_content_by_full_id(full_id)
    while not v:
        var content = await Vars.objects.object_registed
        if content.full_id != full_id: continue
        v = content
        return
