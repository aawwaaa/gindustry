class_name MainNode
extends Node2D

func _ready() -> void:
    get_viewport().gui_embed_subwindows = true

    get_tree().root.process_mode = Node.PROCESS_MODE_ALWAYS

    Log.all_progress_tracker_finished.connect(_on_all_progress_tracker_finished)
    Global.main = self;
    
    init_configs();
    start_load();

func back_to_menu() -> void:
    for node in %Windows.get_children():
        node.hide();
    %GameUI.hide()
    %Loading.visible = false;
    %MainMenu.visible = true;

func hide_all() -> void:
    for node in %Windows.get_children():
        node.hide();
    %GameUI.hide_ui()
    %Loading.visible = false;
    %MainMenu.visible = false;

func show_game_ui() -> void:
    for node in %Windows.get_children():
        node.hide();
    %GameUI.show_ui()
    %Loading.visible = false;
    %MainMenu.visible = false;

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
    %Loading.visible = false;
    %MainMenu.visible = true;
    Global.state.set_state(Global.States.MAIN_MENU);
    Headless.apply_args_from_cmdline()

func init_configs() -> void:
    if not DirAccess.dir_exists_absolute("user://mods/"):
        DirAccess.make_dir_absolute("user://mods/");
    if not DirAccess.dir_exists_absolute("user://saves/"):
        DirAccess.make_dir_absolute("user://saves/");

func start_load() -> void:
    var progress = Log.register_progress_tracker(100, "Main_Load", "Main_LogSource");
    progress.name = "Main_Load_SearchMods"
    Mods.search_mod_folder("res://mods/", false);
    Mods.search_mod_folder("user://mods/");
    Mods.load_enable_configs();
    progress.progress += 5

    # add builtin to mod lists
    Builtin.load_builtin()
    
    progress.name = "Main_Load_CheckModErrors"
    var errors = Mods.check_errors();
    if errors.size() != 0:
        Mods.logger.error(tr("Mods_DetectedExceptsInLoading"))
        for info in Mods.mod_info_list.values():
            info.enabled = false;
        await get_tree().create_timer(3).timeout;
        progress.progress = progress.total
        Mods.display_order = Mods.mod_info_list.keys()
        %Windows/Mods.load_mod_list();
        return;
    
    progress.name = "Main_Load_LoadConfigs"
    Global.load_configs();
    %Windows/Settings.load_tabs()
    progress.progress += 5

    progress.name = "Main_Load_LoadBuiltin"
    await Builtin.start_load()
    progress.progress += 10
    progress.name = "Main_Load_LoadMods"
    await Mods.load_mods();
    progress.progress += 50
    progress.name = "Main_Load_LoadSaves"
    Saves.load_saves();
    progress.progress += 20
    
    progress.name = "Main_Load_LoadUI"
    %Windows/Mods.load_mod_list();
    %Windows/NewGame.load_presets();
    %Windows/Saves.load_saves();
    progress.progress += 5

    progress.name = "Main_Load_LoadUI"
    Game.worlds_node = %Worlds;
    Game.camera_base_node = %CameraBase
    Game.camera_node = %Camera;
    
    GameUI.instance = %GameUI
    
    %GameUI.loaded()
    progress.progress += 3
    
    progress.name = "Main_Load_LoadInputHandler"
    Global.game_ui_input_handler = %GameUI.input_handler_ui
    Global.set_input_handler()
    progress.progress += 2
    progress.finish()
