extends BuildingType

func _get_default_config() -> Variant:
    return []

func _load_config(stream: Stream) -> Variant:
    return ItemSelectAdapter.load_config(stream)

func _save_config(config: Variant, stream: Stream) -> void:
    ItemSelectAdapter.save_config(config, stream)
