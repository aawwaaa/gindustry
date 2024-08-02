class_name Gindustry_Mod
extends Mod

static var instance: Gindustry_Mod = null
static var logger: Log.Logger;

func _mod_init() -> void:
    instance = self
    logger = Log.register_logger("Gindustry");

    await load_resources("mod://resource_types", "Load_LoadTypes", logger.source)

    await load_scripts("mod://src")

func _init_contents() -> void:
    await load_resources("mod://contents", "Load_LoadContents", logger.source)

func _load_contents() -> void:
    pass

func _post() -> void:
    pass

func _open_configs() -> Window:
    return super._open_configs();

