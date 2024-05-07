class_name Vars_Game
extends Vars.Vars_Object

signal save_meta_changed(meta: SaveMeta);
signal current_player_changed(player: Player, from: Player);
signal state_changed(state: States, from: States);

enum States{
    LOADING,
    MAIN_MENU,
    PRESET_CONFIG,
    LOADING_GAME,
    GAME,
    PAUSED
}

var state: StateMachine

func _ready() -> void:
    state = StateMachine.new()
    state.state_changed.connect(func(s, f): state_changed.emit(s, f))

func is_in_game() -> bool:
    return state.get_state() in [States.GAME, States.PAUSED]

func is_in_loading() -> bool:
    return state.get_state() in [States.LOADING, States.LOADING_GAME]

func get_state() -> States:
    return state.get_state()

func set_state(v: States) -> void:
    state.set_state(v)

@rpc("any_peer", "call_local", "reliable")
func set_paused_rpc(v: bool) -> void:
    if not Vars.server.is_peer_admin(Vars.client.get_sender_id()):
        return
    if get_state() not in [States.GAME, States.PAUSED]: return
    var target_state = States.PAUSED if v else States.GAME
    if get_state() != target_state: set_state(target_state)
    Vars.tree.paused = v

func set_paused(v: bool) -> void:
    Vars.server.rpc_node(self, "set_paused_rpc", [v])

func is_paused() -> bool:
    return get_state() == States.PAUSED

# var world_load_source: WorldLoadSource;

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

func cleanup() -> void:
    if save_preset: save_preset._disable_preset()
    Vars.worlds.cleanup()
    save_preset = null
    current_player = null;
    Vars.players.reset_players();

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
    Vars.contents.init_contents_mapping();

func game_loaded() -> void:
    state.set_state(States.GAME)
    Vars.server.send_world_data()
    Vars.server.rpc_node(self, "set_paused_rpc", [false])

func back_to_menu() -> void:
    Vars.client.disconnect_multiplayer()
    cleanup()
    state.set_state(States.MAIN_MENU)

const current_data_version = 0;

func load_game(stream: Stream) -> void:
    reset_game();
    save_meta = SaveMeta.load_from(stream);
    var version = stream.get_16();
    if version < 0: return game_loaded();
    save_configs = ConfigsGroup.load_from(stream);
    Vars.contents.load_contents_mapping(stream);

    save_preset = Vars.types.get_type(Preset.TYPE, stream.get_string()) as Preset
    save_preset._load_preset_data(stream)
    save_preset._enable_preset()
    save_preset._load_preset()
    
    Vars.worlds.load_data(stream)
    Vars.players.load_data(stream)
    save_preset._load_after_world_load()
    game_loaded()

func save_game(stream: Stream, to_client: bool = false) -> void:
    save_meta.save_to(stream);
    stream.store_16(current_data_version)
    # version 0
    save_configs.save_configs(stream);
    Vars.contents.save_contents_mapping(stream);

    stream.store_string(save_preset.name)
    save_preset._save_preset_data(stream)

    Vars.worlds.save_data(stream)
    Vars.players.save_data(stream)

