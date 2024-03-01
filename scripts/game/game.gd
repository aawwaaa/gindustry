extends Node

signal signal_reset_game();
signal signal_init_game();
signal signal_game_loaded();
signal signal_back_to_menu();

signal save_meta_changed(meta: SaveMeta);
signal current_player_changed(player: Player, from: Player);

var in_game: bool = false;
var paused: bool = false:
    set = set_paused;

var camera_node: Camera2D;
var camera_base_node: Node2D;
var worlds_node: Node2D;

var world_load_source: WorldLoadSource;

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

var temp_tile: Tile;

var worlds: Dictionary = {}
var root_world: World;
var world_inc_id = 1;

var entity_inc_id = 1;

var current_player: Player:
    set(v):
        var old = current_player if current_player else null
        current_player = v
        current_player_changed.emit(v, old)

func _ready() -> void:
    create_temp_tile();

@rpc("any_peer", "call_local", "reliable")
func set_paused(v: bool) -> void:
    if not MultiplayerServer.is_peer_admin(multiplayer.get_remote_sender_id()):
        return
    paused = v
    get_tree().paused = v

func create_temp_tile() -> void:
    temp_tile = Tile.new();

func reset_game() -> void:
    signal_reset_game.emit();
    save_preset = null
    world_inc_id = 1;
    entity_inc_id = 1;
    worlds = {};
    root_world = null;
    for world in worlds_node.get_children():
        world.queue_free();
    current_player = null;
    Players.reset_players();
    set_paused.rpc(false)
    create_temp_tile()
    
    Controller._on_game_signal_reset_game();
    Entity._on_game_signal_reset_game();

func init_game() -> void:
    reset_game();
    save_meta = SaveMeta.new();
    save_configs = ConfigsGroup.new();
    Contents.init_contents_mapping();
    signal_init_game.emit();

func game_loaded() -> void:
    signal_game_loaded.emit();
    Global.main.show_game_ui();
    in_game = true;
    Global.state.set_state(Global.States.GAME)

func back_to_menu() -> void:
    Global.state.set_state(Global.States.MAIN_MENU)
    Multiplayer.disconnect_multiplayer()
    signal_back_to_menu.emit();
    reset_game()
    Global.main.back_to_menu();
    in_game = false;

func get_world_or_null(world_id: int) -> World:
    if not worlds.has(world_id):
        return null;
    return worlds[world_id];

func get_world(world_id: int) -> World:
    var world = get_world_or_null(world_id)
    if world:
        return world;
    if not world_load_source:
        return null;
    @warning_ignore("redundant_await")
    world = await world_load_source._load_world(world_id);
    if not world:
        return null;
    worlds[world_id] = world;
    if world.root_world:
        worlds_node.add_child(world);
    return world;

func create_world() -> World:
    if root_world:
        return null;  
    var world = World.create();
    world.world_id = world_inc_id;
    world_inc_id += 1;
    world.root_world = true;
    worlds_node.add_child(world);
    root_world = world;
    worlds[world.world_id] = world;
    return world;

const current_data_version = 0;

func load_game(stream: Stream) -> void:
    reset_game();
    save_meta = SaveMeta.load_from(stream);
    var version = stream.get_16();
    if version < 0: return game_loaded();
    save_configs = ConfigsGroup.load_from(stream);
    Contents.load_contents_mapping(stream);

    save_preset = Contents.get_content_by_index(stream.get_64()) as Preset
    save_preset._load_preset_data(stream)
    save_preset._enable_preset()
    save_preset._load_preset()

    world_inc_id = stream.get_32();
    entity_inc_id = stream.get_64();
    if stream.get_8() == 1:
        var world_id = stream.get_32();
        var world = World.create();
        world.world_id = world_id;
        world.root_world = true;
        root_world = world;
        world.load_data(stream);
        worlds_node.add_child(world);

    Players.load_data(stream)
    game_loaded()

func save_game(stream: Stream, to_client: bool = false) -> void:
    save_meta.save_to(stream);
    stream.store_16(current_data_version)
    # version 0
    save_configs.save_configs(stream);
    Contents.save_contents_mapping(stream);

    stream.store_64(save_preset.index)
    save_preset._save_preset_data(stream)

    stream.store_32(world_inc_id)
    stream.store_64(entity_inc_id)
    stream.store_8(1);
    stream.store_32(root_world.world_id);
    root_world.save_data(stream)

    Players.save_data(stream)

