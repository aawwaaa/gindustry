class_name Vars_Headless
extends Vars.Vars_Object

var headless_client: bool = false

var logger: Log.Logger = Log.register_logger("Headless_LogSource")

func apply_args_from_cmdline() -> void:
    var args = {"_": []}
    var props = {}
    var last_arg = "_"
    for arg in OS.get_cmdline_user_args():
        if arg.find("=") > -1:
            var key_value = arg.split("=")
            props[key_value[0].lstrip("--")] = key_value[1]
        elif arg.begins_with("--"):
            args[arg.lstrip("--")] = []
            last_arg = arg.lstrip("--")
        else:
            args[last_arg].append(arg)
    apply_args(args, props)

func restart(args: PackedStringArray = []) -> void:
    logger.info(tr("Headless_Restart"))
    OS.set_restart_on_exit(true, args)
    exit()

func exit() -> void:
    logger.info(tr("Headless_Exit"))
    Vars.tree.quit()

var props_handlers = {
    "lang" = props_lang,
}

var args_handlers = {
    "help" = args_help,
    "load-save" = args_load_save,
    "load-preset" = args_load_preset,
    "_" = args_default
}

func props_lang(value: String) -> void:
    TranslationServer.set_locale(value)

func args_default(_args: Array = []) -> void:
    pass

func args_help() -> void:
    logger.error("props: " + ", ".join(props_handlers.keys()))
    logger.error("args: " + ", ".join(args_handlers.keys()))

func args_load_save(save_name: String) -> void:
    Vars.saves.load_save(save_name)

func args_load_preset(preset_id: String) -> void:
    var preset = Vars.types.get_type(Preset.TYPE, preset_id) as Preset
    if not preset:
        logger.error(tr("Headless_UnknownPreset {name}").format({name = preset_id}))
        exit()
        return
    Vars.presets.load_preset(preset)

func apply_args(args: Dictionary, props: Dictionary) -> void:
    for prop in props:
        if prop in props_handlers:
            props_handlers[prop].callv(props[prop])
        else:
            logger.error(tr("Headless_UnknownProperty {name}").format({name = prop}))
            exit()
            return
    for arg in args:
        if arg in args_handlers:
            args_handlers[arg].callv(args[arg])
        else:
            logger.error(tr("Headless_UnknownArgument {name}").format({name = arg}))
            exit()
            return
