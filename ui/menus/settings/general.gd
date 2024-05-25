extends RefCounted

var group: Settings.SettingsUIGroup

func load() -> Settings.SettingsUIGroup:
    group = Settings.create("Settings_General")

    var builtin = group.child_group("Settings_General_Builtin")
    builtin.input("player-name", "Player", "Settings_General_PlayerName")
    var input_handlers_button = MenuButton.new()
    input_handlers_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    input_handlers_button.size_flags_stretch_ratio = 3
    input_handlers_button.flat = false
    builtin.add_child_with_label("Settings_General_InputHandler", input_handlers_button)
    var listener_ids = []
    var input_handler = group._get_configs().g("input-handler", Vars.main.get_default_input_handler())
    InputHandler.add_input_handler_listener = func(id, meta):
        if input_handler == id: input_handlers_button.text = meta.tr_name
        listener_ids.append(id)
        input_handlers_button.get_popup().add_item(meta.tr_name)
    input_handlers_button.get_popup().id_pressed.connect(func(id):
        input_handler = listener_ids[id]
        group._get_configs().p("input-handler", input_handler)
        Vars.input.set_input_handler(input_handler)
        input_handlers_button.text = InputHandler.input_handlers[input_handler].tr_name
    )

    return group

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        InputHandler.add_input_handler_listener = Callable()
