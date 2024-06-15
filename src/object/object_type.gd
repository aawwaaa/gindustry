class_name ObjectType
extends Resource

@export var id: String;
var full_id: String = "":
    get:
        if full_id != "": return full_id
        full_id = _get_full_id()
        return full_id
var index: int

var mod: Mod

func _init() -> void:
    if Vars == null or Vars.mods == null:
        mod = null
        return
    mod = Vars.mods.current_loading_mod

# static func generate_full_id(id: String) -> String:
#     if Vars == null or Vars.mods == null: return "builtin_" + id
#     if not Vars.mods.current_loading_mod: return "builtin_" + id
#     return Vars.mods.current_loading_mod.mod_info.id + "_" + id

func get_mod_id() -> String:
    if mod == null: return "builtin"
    return mod.mod_info.id

func get_full_id_default(insert = "") -> String:
    return get_mod_id() + "_" + (insert + "_" if insert else "") + id

func _get_full_id() -> String:
    return get_full_id_default()

func _create() -> RefObject:
    return null

func create(call_create: bool = true) -> RefObject:
    var obj = _create()
    if obj: obj.object_type = self
    if obj and call_create: obj.object_create()
    return obj
