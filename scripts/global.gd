extends Node

signal configs_loaded();
signal input_handler_changed(handler: InputHandler, from: InputHandler);

const CHUNK_SIZE = 16;
const TILE_SIZE = 32;
const TILE_SIZE_VECTOR = Vector2i(TILE_SIZE, TILE_SIZE);

const MAX_LAYERS = 8;
const MAX_LAYERS_MASK = (1 << MAX_LAYERS) - 1

var main: MainNode
var game_ui_input_handler: Control

var configs: ConfigsGroup;
var logger: Log.Logger;
var input_handler: InputHandler;

var headless_client: bool = false;

var config_value_changed = false

func _ready() -> void:
    logger = Log.register_log_source(tr("Global_LogSource"));
    configs = ConfigsGroup.new();

func set_input_handler(name: String = "") -> void:
    if name != "":
        configs.p("input-handler", name)
        save_configs()
    else:
        name = configs.g("input-handler", main.get_default_input_handler())
    var old = input_handler if input_handler else null
    if input_handler:
        input_handler._unload_ui(game_ui_input_handler)
    input_handler = InputHandler.input_handlers[name].input_handler.new()
    add_child(input_handler)
    input_handler._load_ui(game_ui_input_handler)
    input_handler_changed.emit(input_handler, old)
    if old: old.queue_free()

func set_default(key: String, value: Variant) -> void:
    if configs.g(key, null) == null:
        configs.p(key, value)
        config_value_changed = true

func generate_player_configs() -> void:
    set_default("player-token", Utils.generate_token())

    var token_mapping_key = PackedByteArray();
    token_mapping_key.resize(32)
    var rng = RandomNumberGenerator.new();
    rng.randomize();
    for i in range(token_mapping_key.size()):
        token_mapping_key[i] = rng.randi_range(0, 255)
    set_default("token-mapping-key", token_mapping_key)

func load_configs() -> void:
    var progress = Log.register_progress_source(10);
    if not FileAccess.file_exists("user://configs.bin"):
        configs.init_configs();
        logger.warn(tr("Global_ConfigsNotFound"))
        generate_player_configs();
        save_configs();
        progress.call(10);
        return;
    logger.info(tr("Global_LoadConfigs"))
    var access = FileAccess.open("user://configs.bin", FileAccess.READ);
    var stream = FileStream.new(access);
    configs.load_configs(stream);
    access.close();
    configs_loaded.emit()
    generate_player_configs();
    if config_value_changed:
        save_configs()
    progress.call(10);

func save_configs() -> void:
    logger.info(tr("Global_SaveConfigs"))
    var access = FileAccess.open("user://configs.bin", FileAccess.WRITE);
    var stream = FileStream.new(access);
    configs.save_configs(stream);
    access.close();
