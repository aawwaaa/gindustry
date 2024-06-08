extends RefCounted

var group: SettingsUIGroup

func load() -> SettingsUIGroup:
    group = Settings.create("Settings_General")

    var builtin = group.child_group("Settings_General_Builtin")
    builtin.input("Settings_General_PlayerName", Vars_Client.player_name_key)
    var input_handlers_dict = {}
    for id in InputHandler.input_handlers:
        input_handlers_dict[id] = InputHandler.input_handlers[id].tr_name
    var input_handler = builtin.select("Settings_General_InputHandler", \
            Vars_Input.input_handler_key, \
            input_handlers_dict)
    InputHandler.add_input_handler_listener = func(id, meta):
        input_handler.add_selection(id, meta.tr_name)
        input_handler.load_setting()
    input_handler.setting_changed.connect(func(v):
        Vars.input.set_input_handler(v)
    )

    return group

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        InputHandler.add_input_handler_listener = Callable()
