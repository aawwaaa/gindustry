class_name MainNode
extends Node2D

func _ready() -> void:
    get_viewport().gui_embed_subwindows = true

    get_tree().root.process_mode = Node.PROCESS_MODE_ALWAYS

    Log.progress_changed.connect(progress_changed);
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

func progress_changed(_1, part: int, all: int) -> void:
    if part == all:
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
    var progress = Log.register_progress_source(5);
    Mods.search_mod_folder("res://mods/", false);
    Mods.search_mod_folder("user://mods/");
    Mods.load_enable_configs();
    
    var errors = Mods.check_errors();
    if errors.size() != 0:
        Mods.logger.error(tr("Mods_DetectedExceptsInLoading"))
        for info in Mods.mod_info_list.values():
            info.enabled = false;
        await get_tree().create_timer(3).timeout;
        progress.call(5);
        %Windows/Mods.load_mod_list();
        return;
    
    Global.load_configs();
    %Windows/Settings.load_tabs()

    var content_list = preload("res://contents/content_list.gd").new();
    await content_list.start_load()
    await Mods.load_mods();
    Saves.load_saves();
    
    %Windows/Mods.load_mod_list();
    %Windows/NewGame.load_presets();
    %Windows/Saves.load_saves();

    Game.worlds_node = %Worlds;
    Game.camera_base_node = %CameraBase
    Game.camera_node = %Camera;
    
    GameUI.instance = %GameUI
    
    %GameUI.loaded()
    progress.call(5);
    
    Global.game_ui_input_handler = %GameUI.input_handler_ui
    Global.set_input_handler()
