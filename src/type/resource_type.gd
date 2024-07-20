class_name ResourceType
extends Resource

@export var id: String
var mod: Mod

var full_id: String = "";

var type: ResourceType:
    get = get_type

func init_full_id() -> void:
    var mod_id = (mod.mod_info.id + ":") if mod else ""
    if self is ResourceTypeType: full_id = mod_id + id
    else: full_id = mod_id + get_type().id + ":" + id

func _get_type() -> ResourceType:
    return null

func get_type() -> ResourceType:
    return _get_type()

func _type_registed() -> void:
    pass

func _data() -> void:
    pass

func _assign() -> void:
    pass

## Be call when in stage of load contents automatically
func _load() -> void:
    pass

func _load_assets() -> void:
    pass
func _load_headless() -> void:
    pass
