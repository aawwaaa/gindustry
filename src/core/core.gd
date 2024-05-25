class_name Vars_Core
extends Vars.Vars_Object

signal state_changed(state: State, from: State);

enum State{
    LOADING,
    MAIN_MENU,
    PRESET_CONFIG,
    LOADING_GAME,
    IN_GAME,
    RESETING_GAME
}

var state: StateMachine
var logger: Log.Logger = Log.register_logger("Core_LogSource")

func _ready() -> void:
    state = StateMachine.new()
    state.state_changed.connect(func(s, f): state_changed.emit(s, f))

    Log.all_progress_tracker_finished.connect(_on_all_progress_tracker_finished)

func is_in_game() -> bool:
    return state.get_state() == State.IN_GAME

func is_in_main_menu() -> bool:
    return state.get_state() == State.MAIN_MENU

func is_in_loading() -> bool:
    return state.get_state() in [State.LOADING, State.LOADING_GAME, State.RESETING_GAME]

func get_state() -> State:
    return state.get_state() as State

func set_state(v: State) -> void:
    state.set_state(v)

func init_configs() -> void:
    if not DirAccess.dir_exists_absolute("user://mods/"):
        DirAccess.make_dir_absolute("user://mods/");
    if not DirAccess.dir_exists_absolute("user://saves/"):
        DirAccess.make_dir_absolute("user://saves/");

func _on_all_progress_tracker_finished() -> void:
    if state.get_state() == State.LOADING:
        state.set_state(State.MAIN_MENU);
        Vars.headless.apply_args_from_cmdline()

func start_load() -> void:
    state.set_state(State.LOADING);
    var progress = Log.register_progress_tracker(100, "Core_Load", logger.source);
    progress.name = "Core_Load_SearchMods"
    Vars.mods.search_mod_folder("res://mods/", false);
    Vars.mods.search_mod_folder("user://mods/");
    Vars.mods.load_enable_configs();
    progress.progress += 5

    # add builtin to mod lists
    Builtin.load_builtin()
    
    progress.name = "Core_Load_CheckModErrors"
    var errors = Vars.mods.check_errors();
    if errors.size() != 0:
        Vars.mods.logger.error(tr("Core_DetectedExceptsInLoading"))
        for info in Vars.mods.mod_info_list.values():
            info.enabled = false;
        await get_tree().create_timer(3).timeout;
        progress.progress = progress.total
        Vars.mods.display_order = Vars.mods.mod_info_list.keys()
        Vars.main.get_window_node("Mods").load_mod_list();
        return;
    
    progress.name = "Core_Load_LoadConfigs"
    Vars.configs.load_configs();
    Vars.main.get_window_node("Settings").load_tabs()
    progress.progress += 5

    progress.name = "Core_Load_LoadBuiltin"
    await Builtin.start_load()
    progress.progress += 10
    progress.name = "Core_Load_LoadMods"
    await Vars.mods.load_mods();
    progress.progress += 50
    progress.name = "Core_Load_LoadSaves"
    Vars.saves.load_saves();
    progress.progress += 20
    
    Vars.main.load_ui(progress)

    Vars.game.reset_game();
    progress.finish()
