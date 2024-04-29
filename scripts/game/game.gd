extends Node

signal save_meta_changed(meta: SaveMeta);
signal current_player_changed(player: Player, from: Player);

var paused: bool = false;

var camera_node: Camera3D;
var camera_base_node: Node3D;

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

var worlds: Dictionary = {}
var world_inc_id = 1;

var entity_inc_id = 1;

var current_player: Player:
    set(v):
        var old = current_player if current_player else null
        current_player = v
        current_player_changed.emit(v, old)
# var current_entity: Entity:
#     get: return current_player.get_controller().entity if current_player else null

# func _ready() -> void:
#     create_temp_tile();

@rpc("any_peer", "call_local", "reliable")
func set_paused_rpc(v: bool) -> void:
    if not MultiplayerServer.is_peer_admin(multiplayer.get_remote_sender_id()):
        return
    paused = v
    get_tree().paused = v

func set_paused(v: bool) -> void:
    MultiplayerServer.rpc_sync(self, "set_paused_rpc", [v])
    Global.state.set_state(Global.States.PAUSED if v else Global.States.GAME)

func is_in_game() -> bool:
    var state = Global.state.get_state();
    return state == Global.States.GAME or state == Global.States.PAUSED

# func create_temp_tile() -> void:
#     temp_tile = Tile.new();

func cleanup() -> void:
    if save_preset: save_preset._disable_preset()
    for world in worlds.values():
        world.free()
    save_preset = null
    world_inc_id = 1;
    entity_inc_id = 1;
    worlds = {};
    current_player = null;
    Players.reset_players();

func reset_game() -> void:
    cleanup()
    MultiplayerServer.rpc_sync(self, "set_paused_rpc", [true])
    Global.state.set_state(Global.States.LOADING_GAME)
#     create_temp_tile()
    
#     Controller._on_game_signal_reset_game();
#     Entity._on_game_signal_reset_game();

func init_game() -> void:
    reset_game();
    save_meta = SaveMeta.new();
    save_configs = ConfigsGroup.new();
    Contents.init_contents_mapping();

func game_loaded() -> void:
    Global.state.set_state(Global.States.GAME)
    MultiplayerServer.send_world_data()
    MultiplayerServer.rpc_sync(self, "set_paused_rpc", [false])

func back_to_menu() -> void:
    Multiplayer.disconnect_multiplayer()
    cleanup()
    Global.state.set_state(Global.States.MAIN_MENU)

func get_world_or_null(world_id: int) -> World:
    if not worlds.has(world_id):
        return null;
    return worlds[world_id];

func get_world(world_id: int) -> World:
    var world = get_world_or_null(world_id)
    if world:
        return world;
#     if not world_load_source:
#         return null;
    @warning_ignore("redundant_await")
#     world = await world_load_source._load_world(world_id);
    if not world:
        return null;
    worlds[world_id] = world;
    return world;

func create_world() -> World:
    var world = World.create();
    world.world_id = world_inc_id;
    world_inc_id += 1;
    world.root_world = true;
    worlds[world.world_id] = world;
    world.create_resources()
    return world;

const current_data_version = 0;

func load_game(stream: Stream) -> void:
    reset_game();
    save_meta = SaveMeta.load_from(stream);
    var version = stream.get_16();
    if version < 0: return game_loaded();
    save_configs = ConfigsGroup.load_from(stream);
    Contents.load_contents_mapping(stream);

    save_preset = Types.get_type(Preset.TYPE, stream.get_string()) as Preset
    save_preset._load_preset_data(stream)
    save_preset._enable_preset()
    save_preset._load_preset()

    world_inc_id = stream.get_32();
    entity_inc_id = stream.get_64();
    for _1 in stream.get_32():
        var world_id = stream.get_32();
        var world = World.create();
        world.world_id = world_id;
        worlds[world_id] = world
        world.load_data(stream);

    Players.load_data(stream)
    save_preset._load_after_world_load()
    game_loaded()

func save_game(stream: Stream, to_client: bool = false) -> void:
    save_meta.save_to(stream);
    stream.store_16(current_data_version)
    # version 0
    save_configs.save_configs(stream);
    Contents.save_contents_mapping(stream);

    stream.store_string(save_preset.name)
    save_preset._save_preset_data(stream)

    stream.store_32(world_inc_id)
    stream.store_64(entity_inc_id)
    stream.store_32(worlds.size())
    for world in worlds.values():
        stream.store_32(world.world_id)
        world.save_data(world)

    Players.save_data(stream)

