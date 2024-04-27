class_name Gindustry
extends Mod

static var root = "res://mods/gindustry"
static var logger: Log.Logger;

func _init(info: ModInfo) -> void:
    super._init(info);
    logger = Log.register_log_source("Gindustry");

func _mod_init() -> void:
    #logger.info("Hello world from mod!")
    pass

func _load_contents() -> void:
    var preset = load(root+"/contents/presets/test.tres")
    Presets.register_preset_group("Gindustry").add(preset)

func _open_configs() -> Window:
    return super._open_configs();

