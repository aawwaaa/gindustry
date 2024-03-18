class_name Content
extends Resource

@export var id: String;
@export var options: Dictionary = {};
var full_id: String;

var index: int:
    get = get_index,
    set = set_index
var mod: Mod;

static func to_full_id(mod_id: String, content_id: String, insert: String = "") -> String:
    if insert:
        return mod_id + "_" + insert + "_" + content_id;
    return mod_id + "_" + content_id;

func apply_mod(mod_inst: Mod) -> void:
    mod = mod_inst;
    full_id = Content.to_full_id(mod.mod_info.id, id, get_content_type().name)

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id)

func _get_content_type() -> ContentType:
    return Types.get_type(ContentType.TYPE, "content")

func get_content_type() -> ContentType:
    return _get_content_type()

func _get_default_option(name: StringName) -> Variant:
    return null

func get_option(name: StringName) -> Variant:
    if not options.has(name):
        return _get_default_option(name)
    return options[name]

func _content_registed() -> void:
    pass

func get_index() -> int:
    return index

func set_index(v: int) -> void:
    index = v
