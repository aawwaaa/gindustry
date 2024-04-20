extends BuildingShadow_ConveyorModule

func _set_building_config(config: Variant) -> void:
    super._set_building_config(config)
    AdapterConfig.apply_shadow(config, {
        ItemSelectAdapter.CONFIG_KEY: {
            ItemSelectAdapter.CONFIG_TARGET_CONTENT_DISPLAY_GROUP: get_sub_node("group"),
            ItemSelectAdapter.CONFIG_TARGET_SPRITE2D: {
                ItemSelectAdapter.CONFIG_TARGET_SPRITE2D_NODE: display_sprite,
                ItemSelectAdapter.CONFIG_TARGET_SPRITE2D_WHITELIST_TEXTURE: building_type.texture_texture,
                ItemSelectAdapter.CONFIG_TARGET_SPRITE2D_BLACKLIST_TEXTURE: building_type.texture_blacklist_texture
            }
        }
    })

