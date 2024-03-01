extends Node

var logger: Log.Logger;

func _ready() -> void:
    logger = Log.register_log_source("Presets_LogSource")

class PresetGroup:
    var group_name: String = "unnamed"
    var presets: Array[Preset] = []
    
    func add(preset: Preset) -> void:
        presets.append(preset)
        Contents.register_content(preset)

var preset_groups: Array[PresetGroup] = []

func register_preset_group(group_name: String) -> PresetGroup:
    var group = PresetGroup.new();
    group.group_name = group_name
    preset_groups.append(group)
    return group;

func load_preset(preset: Preset) -> void:
    logger.info(tr("Presets_LoadPreset {name}") \
        .format({name = tr(preset.get_tr_name())}))
    Global.main.hide_all();
    Global.state.set_state(Global.States.PRESET_CONFIG)
    var result = await preset._pre_config_preset();
    if not result:
        Global.state.set_state(Global.States.MAIN_MENU)
        return
    Game.init_game()
    Game.save_preset = preset
    preset._enable_preset()
    preset._init_preset();
    var player = Multiplayer.join_local()
    preset._init_after_world_load()
    preset._load_preset();
    Game.game_loaded()

