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

func is_in_game() -> bool:
    return state.get_state() == State.IN_GAME

func is_in_main_menu() -> bool:
    return state.get_state() == State.MAIN_MENU

func is_in_loading() -> bool:
    return state.get_state() in [State.LOADING, State.LOADING_GAME, State.RESETING_GAME]

func get_state() -> State:
    return state.get_state()

func set_state(v: State) -> void:
    state.set_state(v)

func start_load() -> void:
    pass
