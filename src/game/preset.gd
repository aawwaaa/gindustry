class_name Preset
extends ResourceType

const TYPE = preload("res://contents/resource_types/preset.tres")

func _get_type() -> ResourceType:
    return TYPE

func _show_description(_node: ScrollContainer) -> void:
    pass

func _pre_config_preset() -> bool:
    return true

func _init_preset() -> void:
    pass

func _init_after_world_load() -> void:
    pass

func _load_after_world_load() -> void:
    pass

func _after_ready() -> void:
    pass

func _apply_preset() -> void:
    pass

func _reset_preset() -> void:
    pass

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, name, "preset")

func _enable_preset() -> void:
    pass

func _disable_preset() -> void:
    pass

func _load_preset_data(_stream: Stream) -> Error:
    return OK

func _save_preset_data(_stream: Stream) -> void:
    pass

"""
pre_config -> true -> enable -> init -> load -> ...
           -> false -> back_to_menu
load_preset_data -> enable -> load -> ...
... -> save_preset_data -> ... -> disable_preset

"""
