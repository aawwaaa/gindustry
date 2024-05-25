class_name Vars_Presets
extends Vars.Vars_Object

var logger: Log.Logger;

func _ready() -> void:
    logger = Log.register_logger("Presets_LogSource")

class PresetGroup:
    var group_name: String = "unnamed"
    var presets: Array[Preset] = []
    
    func add(preset: Preset) -> void:
        presets.append(preset)
        Vars.types.register_type(preset)

var preset_groups: Array[PresetGroup] = []

func register_preset_group(group_name: String) -> PresetGroup:
    var group = PresetGroup.new();
    group.group_name = group_name
    preset_groups.append(group)
    return group;

func load_preset(preset: Preset) -> void:
    logger.info(tr("Presets_LoadPreset {name}") \
        .format({name = tr(preset.get_tr_name())}))
    Vars.core.state.set_state(Vars_Core.State.PRESET_CONFIG)
    @warning_ignore("redundant_await")
    var result = await preset._pre_config_preset();
    if not result:
        Vars.core.state.set_state(Vars_Core.State.MAIN_MENU)
        return
    Vars.game.init_game()
    Vars.game.save_preset = preset
    preset._enable_preset()
    preset._init_preset();
    var _player = Vars.client.join_local()
    preset._init_after_world_load()
    preset._load_preset();
    Vars.game.ready_game()
    preset._after_ready();

