class_name ResourceType
extends Resource

@export var name: String
var mod: Mod

var full_id: String = "";

func init_full_id() -> void:
    var mod_id = (mod.mod_info.id + "_") if mod else ""
    if self is ResourceTypeType: full_id = mod_id + name
    else: full_id = mod_id + get_type().name + "_" + name

func _get_type() -> ResourceType:
    return null

func get_type() -> ResourceType:
    return _get_type()

