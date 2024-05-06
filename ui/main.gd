class_name MainNode
extends Node2D

var logger: Log.Logger

func _ready() -> void:
    get_viewport().gui_embed_subwindows = true

    get_tree().root.process_mode = Node.PROCESS_MODE_ALWAYS
    
    logger = Log.register_logger("Main_LogSource")
    Log.all_progress_tracker_finished.connect(_on_all_progress_tracker_finished)
    G.init()
    G.game.state.state_changed.connect(_on_state_changed)
    G.main = self;
    
    init_configs();

    G.game.set_state(G.game.States.LOADING);
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
    if G.game.get_state() == G.game.States.LOADING:
        G.game.set_state(G.game.States.MAIN_MENU);
        G.headless.apply_args_from_cmdline()

func _on_state_changed(state: G_Game.States, from: G_Game.States) -> void:
    for node in %Windows.get_children():
        node.hide();
    %Loading.visible = G.game.is_in_loading()
    %MainMenu.visible = G.game.get_state() == G.game.States.MAIN_MENU;
    if G.game.is_in_game():
        %GameUI.show_ui()
    else:
        %GameUI.hide_ui()
    logger.info(tr("Main_StateChanged {from} {state}").format({
        from = G.game.States.find_key(from),
        state = G.game.States.find_key(state)}
    ))

func init_configs() -> void:
    if not DirAccess.dir_exists_absolute("user://mods/"):
        DirAccess.make_dir_absolute("user://mods/");
    if not DirAccess.dir_exists_absolute("user://saves/"):
        DirAccess.make_dir_absolute("user://saves/");

func start_load() -> void:
    var progress = Log.register_progress_tracker(100, "Main_Load", logger.source);
    progress.name = "Main_Load_SearchMods"
    G.mods.search_mod_folder("res://mods/", false);
    G.mods.search_mod_folder("user://mods/");
    G.mods.load_enable_configs();
    progress.progress += 5

    # add builtin to mod lists
    Builtin.load_builtin()
    
    progress.name = "Main_Load_CheckModErrors"
    var errors = G.mods.check_errors();
    if errors.size() != 0:
        G.mods.logger.error(tr("Mods_DetectedExceptsInLoading"))
        for info in G.mods.mod_info_list.values():
            info.enabled = false;
        await get_tree().create_timer(3).timeout;
        progress.progress = progress.total
        G.mods.display_order = G.mods.mod_info_list.keys()
        %Windows/Mods.load_mod_list();
        return;
    
    progress.name = "Main_Load_LoadConfigs"
    G.configs.load_configs();
    %Windows/Settings.load_tabs()
    progress.progress += 5

    progress.name = "Main_Load_LoadBuiltin"
    await Builtin.start_load()
    progress.progress += 10
    progress.name = "Main_Load_LoadMods"
    await G.mods.load_mods();
    progress.progress += 50
    progress.name = "Main_Load_LoadSaves"
    G.saves.load_saves();
    progress.progress += 20
    
    progress.name = "Main_Load_LoadUI"
    %Windows/Mods.load_mod_list();
    %Windows/NewGame.load_presets();
    %Windows/Saves.load_saves();
    progress.progress += 5

    progress.name = "Main_Load_LoadUI"
    G.input.camera_base_node = %CameraBase
    G.input.camera_node = %Camera;
    
    GameUI.instance = %GameUI
    
    %GameUI.loaded()
    progress.progress += 3
    
    progress.name = "Main_Load_LoadInputHandler"
    G.input.ui_node = %GameUI.input_handler_ui
    # G.input.set_input_handler()
    progress.progress += 2
    progress.finish()
