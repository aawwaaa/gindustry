extends BuildingShadow

func _set_building_config(config: Variant) -> void:
    super._set_building_config(config)
    if not config: return
    ItemSelectAdapter.apply_config_to_display_group(config, get_sub_node("group"))

