extends BuildingShadow

func _set_building_config(config: Variant) -> void:
    super._set_building_config(config)
    if not config: return
    AdapterConfig.apply_shadow(config, {
        ItemSelectAdapter.CONFIG_KEY: {
            ItemSelectAdapter.CONFIG_TARGET_CONTENT_DISPLAY_GROUP: get_sub_node("group")
        }
    })

