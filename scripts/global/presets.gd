class_name G_Presets
extends G.G_Object

var logger: Log.Logger;

func _ready() -> void:
    logger = Log.register_log_source("Presets_LogSource")

class PresetGroup:
    var group_name: String = "unnamed"
    var presets: Array[Preset] = []
    
    func add(preset: Preset) -> void:
        presets.append(preset)
        G.types.register_type(preset)

var preset_groups: Array[PresetGroup] = []

func register_preset_group(group_name: String) -> PresetGroup:
    var group = PresetGroup.new();
    group.group_name = group_name
    preset_groups.append(group)
    return group;

func load_preset(preset: Preset) -> void:
    logger.info(tr("Presets_LoadPreset {name}") \
        .format({name = tr(preset.get_tr_name())}))
    G.game.set_state(G.game.States.PRESET_CONFIG)
    var result = await preset._pre_config_preset();
    if not result:
        G.game.set_state(G.game.States.MAIN_MENU)
        return
    G.game.init_game()
    G.game.save_preset = preset
    preset._enable_preset()
    preset._init_preset();
    var player = G.client.join_local()
    preset._init_after_world_load()
    preset._load_preset();
    G.game.game_loaded()

