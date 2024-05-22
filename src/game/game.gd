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

# var temp_tile: Tile;

var current_player: Player:
    set(v):
        var old = current_player if current_player else null
        current_player = v
        current_player_changed.emit(v, old)
# var current_entity: Entity:
#     get: return current_player.get_controller().entity if current_player else null

# func create_temp_tile() -> void:
#     temp_tile = Tile.new();

func __set_paused(v: bool) -> void:
    __is_paused = v
    get_tree().paused = v
    PhysicsServer3D.set_active(not v)

func _on_state_state_changed(state: Vars_Core.State, from: Vars_Core.State) -> void:
    if state != Vars_Core.State.IN_GAME:
        __set_paused(true)
    else:
        __set_paused(false)

func is_paused() -> bool:
    return __is_paused

func cleanup() -> void:
    if save_preset: save_preset._disable_preset()
    Vars.worlds.reset()
    Vars.objects.cleanup()
    save_preset = null
    current_player = null;
    Vars.players.reset();

func reset_game() -> void:
    cleanup()
    Vars.server.rpc_node(self, "set_paused_rpc", [true])
    state.set_state(States.LOADING_GAME)
#     create_temp_tile()
    
#     Controller._on_game_signal_reset_game();
#     Entity._on_game_signal_reset_game();

func init_game() -> void:
    reset_game();
    save_meta = SaveMeta.new();
    save_configs = ConfigsGroup.new();
    Vars.objects.init_object_types_mapping();
    Vars.contents.init_contents_mapping();
    Vars.objects.object_ready()

func game_loaded() -> void:
    state.set_state(States.GAME)
    Vars.server.send_world_data()
    Vars.server.rpc_node(self, "set_paused_rpc", [false])

func back_to_menu() -> void:
    Vars.client.disconnect_multiplayer()
    cleanup()
    state.set_state(States.MAIN_MENU)

const current_data_version = 0;

func load_game(stream: Stream, call_loaded: bool = true) -> void:
    reset_game();
    save_meta = SaveMeta.load_from(stream);
    var version = stream.get_16();
    if version < 0: return game_loaded();
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
    Vars.objects.object_ready()
    if call_loaded: game_loaded()

func save_game(stream: Stream, to_client: bool = false) -> void:
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

