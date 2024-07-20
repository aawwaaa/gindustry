extends Mod

var logger: Log.Logger;

func _mod_init() -> void:
    logger = Log.register_logger("Gindustry");

    await load_resources("/resource_types", "Load_LoadTypes", logger.source)

func _init_contents() -> void:
    await load_resources("/contents", "Load_LoadContents", logger.source)

func _load_contents() -> void:
    pass

func _post() -> void:
    pass

func _open_configs() -> Window:
    return super._open_configs();

