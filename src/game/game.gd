class_name Vars_Game
extends Vars.Vars_Object

signal save_meta_changed(meta: SaveMeta);
signal current_player_changed(player: Player, from: Player);

var __is_paused: bool

var save_preset: Preset:
    set(v):
        if save_preset:
            save_preset._disable_preset();
        save_preset = v
var save_meta: SaveMeta:
    set(v):
        save_meta = v
        save_meta_changed.emit(v)
var save_configs: ConfigsGroup = ConfigsGroup.new();

var current_player: Player:
    set(v):
        var old = current_player if current_player else null
        current_player = v
        current_player_changed.emit(v, old)

# RPC Call this
func __set_paused(v: bool) -> void:
    __is_paused = v
    get_tree().paused = v
    PhysicsServer3D.set_active(not v)

func _on_state_state_changed(state: Vars_Core.State, from: Vars_Core.State) -> void:
    if state != Vars_Core.State.IN_GAME:
        __set_paused(true)
    else:
        __set_paused(false)
    if from == Vars_Core.State.IN_GAME and state != Vars_Core.State.IN_GAME:
        reset_game()
    if from == Vars_Core.State.LOADING_GAME and state != Vars_Core.State.IN_GAME:
        reset_game()

func is_paused() -> bool:
    return __is_paused

func reset_game() -> void:
    if save_preset: save_preset._disable_preset()
    Vars.worlds.reset()
    Vars.objects.reset()

    save_preset = null
    current_player = null;

    Vars.players.reset();
    
    Vars.client.reset();
    Vars.server.reset();

func start_game_load() -> void:
    Vars.core.state.set_state(Vars_Core.State.LOADING_GAME)

func init_game() -> void:
    save_meta = SaveMeta.new();
    save_configs = ConfigsGroup.new();
    Vars.objects.init_object_types_mapping();
    Vars.contents.init_contents_mapping();

func ready_game() -> void:
    Vars.objects.object_ready()
    Vars.core.state.set_state(Vars_Core.State.IN_GAME)

const current_data_version = 0;

func load_game(stream: Stream) -> void:
    start_game_load();
    save_meta = SaveMeta.load_from(stream);
    var version = stream.get_16();
    if version < 0: return ready_game();
    save_configs = ConfigsGroup.load_from(stream);
    Vars.objects.load_object_types_mapping(stream);
    Vars.contents.load_contents_mapping(stream);

    save_preset = Vars.types.get_type(Preset.TYPE, stream.get_string()) as Preset
    save_preset._load_preset_data(stream)
    save_preset._enable_preset()
    save_preset._load_preset()
    
    Vars.worlds.load_data(stream)
    Vars.players.load_data(stream)
    save_preset._load_after_world_load()
    ready_game();
    save_preset._after_ready();

func save_game(stream: Stream, _to_client: bool = false) -> void:
    save_meta.save_to(stream);
    stream.store_16(current_data_version)
    # version 0
    save_configs.save_configs(stream);
    Vars.objects.save_object_types_mapping(stream);
    Vars.contents.save_contents_mapping(stream);

    stream.store_string(save_preset.name)
    save_preset._save_preset_data(stream)

    Vars.worlds.save_data(stream)
    Vars.players.save_data(stream)

