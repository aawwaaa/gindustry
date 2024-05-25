class_name MainNode
extends Node3D

var logger: Log.Logger

func _ready() -> void:
    get_viewport().gui_embed_subwindows = true

    get_tree().root.process_mode = Node.PROCESS_MODE_ALWAYS
    
    logger = Log.register_logger("Main_LogSource")
    Vars.init()
    Vars.core.state.state_changed.connect(_on_state_changed)
    Vars.main = self;
    
    Vars.core.init_configs()
    Vars.core.start_load()

func _on_viewport_size_changed() -> void:
    pass

func open_window(window_name: String) -> void:
    %Windows.get_node(window_name).show()

func get_window_node(window_name: String) -> Control:
    return %Windows.get_node(window_name)

func get_default_input_handler() -> String:
    return "desktop"

func _on_saves_pressed() -> void:
    get_window_node("Saves").set_save_ui(false)
    open_window("Saves")

func _on_state_changed(state: Vars_Core.State, from: Vars_Core.State) -> void:
    for node in %Windows.get_children():
        node.hide();
    %Loading.visible = Vars.core.is_in_loading()
    %MainMenu.visible = Vars.core.state.get_state() == Vars_Core.State.MAIN_MENU;
    if Vars.core.is_in_game():
        %GameUI.show_ui()
    else:
        %GameUI.hide_ui()
    logger.info(tr("Main_StateChanged {from} {state}").format({
        from = tr("Core_State_" + str(Vars_Core.State.find_key(from))),
        state = tr("Core_State_" + str(Vars_Core.State.find_key(state)))}
    ))

func load_ui(progress: Log.ProgressTracker) -> void:
    # total: 10

    progress.name = "Main_Load_LoadUI"
    %Windows/Mods.load_mod_list();
    %Windows/NewGame.load_presets();
    %Windows/Saves.load_saves();
    progress.progress += 5

    progress.name = "Main_Load_LoadGameUI"
    GameUI.instance = %GameUI

    get_viewport().size_changed.connect(_on_viewport_size_changed)
    _on_viewport_size_changed()
    
    %GameUI.loaded()
    progress.progress += 3
    
    progress.name = "Main_Load_LoadInputHandler"
    Vars.input.ui_node = %GameUI.input_handler_ui

    # Vars.input.set_input_handler()
    progress.progress += 2
