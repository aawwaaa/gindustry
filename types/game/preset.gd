class_name Preset
extends Content

func _show_description(_node: ScrollContainer) -> void:
    pass

func _pre_config_preset() -> bool:
    return true

func _init_preset() -> void:
    pass

func _init_after_world_load() -> void:
    pass

func _load_preset() -> void:
    pass

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "preset")

func _get_content_type() -> String:
    return "preset"

func _enable_preset() -> void:
    pass

func _disable_preset() -> void:
    pass

func _load_preset_data(stream: Stream) -> void:
    pass

func _save_preset_data(stream: Stream) -> void:
    pass

"""
pre_config -> true -> enable -> init -> load -> ...
           -> false -> back_to_menu
load_preset_data -> enable -> load -> ...
... -> save_preset_data -> ... -> disable_preset

"""
