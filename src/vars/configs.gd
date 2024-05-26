class_name Vars_Configs
extends Vars.Vars_Object

signal configs_loaded();

var configs: ConfigsGroup = ConfigsGroup.new();
var logger: Log.Logger = Log.register_logger(tr("Global_LogSource"));

var config_value_changed = false

func g(key: String, default: Variant = null) -> Variant:
    return configs.g(key, default)

func k(key: ConfigsGroup.ConfigKey) -> Variant:
    return configs.k(key)

func p(key: String, value: Variant) -> void:
    configs.p(key, value)

func set_default(key: String, value: Variant) -> void:
    if configs.g(key, null) == null:
        configs.p(key, value)
        config_value_changed = true

func generate_player_configs() -> void:
    set_default(Player.PLAYER_TOKEN_CONFIG, Utils.generate_token())

    var token_mapping_key = PackedByteArray();
    token_mapping_key.resize(32)
    var rng = RandomNumberGenerator.new();
    rng.randomize();
    for i in range(token_mapping_key.size()):
        token_mapping_key[i] = rng.randi_range(0, 255)
    set_default(Vars_Players.TOKEN_MAPPING_KEY_CONFIG, token_mapping_key)

func load_configs() -> void:
    if not FileAccess.file_exists("user://configs.bin"):
        configs.init_configs();
        logger.warn(tr("Global_ConfigsNotFound"))
        generate_player_configs();
        save_configs();
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

func save_configs() -> void:
    logger.info(tr("Global_SaveConfigs"))
    var access = FileAccess.open("user://configs.bin", FileAccess.WRITE);
    var stream = FileStream.new(access);
    configs.save_configs(stream);
    access.close();

