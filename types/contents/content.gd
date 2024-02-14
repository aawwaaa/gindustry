class_name Content
extends Resource

@export var id: String;
var full_id: String;

var index: int;
var mod: Mod;

static func to_full_id(mod_id: String, content_id: String, insert: String = "") -> String:
    if insert:
        return mod_id + "_" + insert + "_" + content_id;
    return mod_id + "_" + content_id;

func apply_mod(mod_inst: Mod) -> void:
    mod = mod_inst;
    full_id = Content.to_full_id(mod.mod_info.id, id)

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id)

func _get_content_type() -> String:
    return "content"

func _content_registed() -> void:
    pass
