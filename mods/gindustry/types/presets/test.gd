extends Preset

func _get_type() -> ResourceType:
    return TYPE

func _show_description(node: ScrollContainer) -> void:
    var label = Label.new()
    label.text = tr("Gindustry_Presets_Test_Description")
    node.add_child(label)

func _pre_config_preset() -> bool:
    return true

func _init_preset() -> void:
    var world = Game.create_world()

func _init_after_world_load() -> void:
    pass

func _load_preset() -> void:
    await Game.signal_game_loaded

func _enable_preset() -> void:
    pass

func _disable_preset() -> void:
    pass

func _load_preset_data(stream: Stream) -> void:
    pass

func _save_preset_data(stream: Stream) -> void:
    pass
