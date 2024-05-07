class_name MainNode
extends Node2D

var logger: Log.Logger

func _ready() -> void:
    get_viewport().gui_embed_subwindows = true

    get_tree().root.process_mode = Node.PROCESS_MODE_ALWAYS
    
    logger = Log.register_logger("Main_LogSource")
    Log.all_progress_tracker_finished.connect(_on_all_progress_tracker_finished)
    Vars.init()
    Vars.game.state.state_changed.connect(_on_state_changed)
    Vars.main = self;
    
    init_configs();

    Vars.game.set_state(Vars.game.States.LOADING);
    start_load();

func open_window(window_name: String) -> void:
    %Windows.get_node(window_name).show()

func get_window_node(window_name: String) -> Control:
    return %Windows.get_node(window_name)

func get_default_input_handler() -> String:
    return "desktop"

func _on_saves_pressed() -> void:
    get_window_node("Saves").set_save_ui(false)
    open_window("Saves")

func _on_all_progress_tracker_finished() -> void:
    if Vars.game.get_state() == Vars.game.States.LOADING:
        Vars.game.set_state(Vars.game.States.MAIN_MENU);
        Vars.headless.apply_args_from_cmdline()

func _on_state_changed(state: Vars_Game.States, from: Vars_Game.States) -> void:
    for node in %Windows.get_children():
        node.hide();
    %Loading.visible = Vars.game.is_in_loading()
    %MainMenu.visible = Vars.game.get_state() == Vars.game.States.MAIN_MENU;
    if Vars.game.is_in_game():
        %GameUI.show_ui()
    else:
        %GameUI.hide_ui()
    logger.info(tr("Main_StateChanged {from} {state}").format({
        from = Vars.game.States.find_key(from),
        state = Vars.game.States.find_key(state)}
    ))

func init_configs() -> void:
    if not DirAccess.dir_exists_absolute("user://mods/"):
        DirAccess.make_dir_absolute("user://mods/");
    if not DirAccess.dir_exists_absolute("user://saves/"):
        DirAccess.make_dir_absolute("user://saves/");

func start_load() -> void:
    var progress = Log.register_progress_tracker(100, "Main_Load", logger.source);
    progress.name = "Main_Load_SearchMods"
    Vars.mods.search_mod_folder("res://mods/", false);
    Vars.mods.search_mod_folder("user://mods/");
    Vars.mods.load_enable_configs();
    progress.progress += 5

    # add builtin to mod lists
    Builtin.load_builtin()
    
    progress.name = "Main_Load_CheckModErrors"
    var errors = Vars.mods.check_errors();
    if errors.size() != 0:
        Vars.mods.logger.error(tr("Mods_DetectedExceptsInLoading"))
        for info in Vars.mods.mod_info_list.values():
            info.enabled = false;
        await get_tree().create_timer(3).timeout;
        progress.progress = progress.total
        Vars.mods.display_order = Vars.mods.mod_info_list.keys()
        %Windows/Mods.load_mod_list();
        return;
    
    progress.name = "Main_Load_LoadConfigs"
    Vars.configs.load_configs();
    %Windows/Settings.load_tabs()
    progress.progress += 5

    progress.name = "Main_Load_LoadBuiltin"
    await Builtin.start_load()
    progress.progress += 10
    progress.name = "Main_Load_LoadMods"
    await Vars.mods.load_mods();
    progress.progress += 50
    progress.name = "Main_Load_LoadSaves"
    Vars.saves.load_saves();
    progress.progress += 20
    
    progress.name = "Main_Load_LoadUI"
    %Windows/Mods.load_mod_list();
    %Windows/NewGame.load_presets();
    %Windows/Saves.load_saves();
    progress.progress += 5

    progress.name = "Main_Load_LoadUI"
    Vars.input.camera_base_node = %CameraBase
    Vars.input.camera_node = %Camera;
    
    GameUI.instance = %GameUI
    
    %GameUI.loaded()
    progress.progress += 3
    
    progress.name = "Main_Load_LoadInputHandler"
    Vars.input.ui_node = %GameUI.input_handler_ui
    # Vars.input.set_input_handler()
    progress.progress += 2
    progress.finish()
