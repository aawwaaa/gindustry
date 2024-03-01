class_name StateMachine
extends Node

const KEEP_CURRENT_STATE: int = -1

signal state_changed(new_state: int, old_state: int)

var state: int = -1

func get_state() -> int:
    return state

func _get_next_state(state: int, delta: float) -> int:
    return KEEP_CURRENT_STATE

func update_state(delta: float) -> void:
    var old_state = state
    var new_state = _get_next_state(state, delta)
    if new_state != KEEP_CURRENT_STATE:
        state = new_state
        emit_signal("state_changed", state, old_state)
        update_state(0)

func set_state(new_state: int) -> void:
    var old_state = state
    state = new_state
    emit_signal("state_changed", state, old_state)
