class_name G_Headless
extends G.G_Object

var headless_client: bool = false

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
    OS.set_restart_on_exit(true, args)
    G.tree.quit()

var props_handlers = {
    "lang" = props_lang,
}

var args_handlers = {
    "help" = args_help,
    "load-save" = args_load_save,
    "_" = args_default
}

func props_lang(value: String) -> void:
    TranslationServer.set_locale(value)

func args_default(args: Array = []) -> void:
    pass

func args_help() -> void:
    print("props: " + ", ".join(props_handlers.keys()))
    print("args: " + ", ".join(args_handlers.keys()))

func args_load_save(save_name: String) -> void:
    G.saves.load_save(save_name)

func apply_args(args: Dictionary, props: Dictionary) -> void:
    for prop in props:
        if prop in props_handlers:
            props_handlers[prop].callv(props[prop])
        else:
            print(tr("Headless_UnknownProperty {name}").format({name = prop}))
    for arg in args:
        if arg in args_handlers:
            args_handlers[arg].callv(args[arg])
        else:
            print(tr("Headless_UnknownArgument {name}").format({name = arg}))
