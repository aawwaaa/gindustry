class_name StateMachine
extends Node

const KEEP_CURRENT_STATE: int = -1

signal state_changed(new_state: int, old_state: int)

var state: int = -1

func _init(default_state: int = -1) -> void:
    state = default_state

func get_state() -> int:
    return state

func _get_next_state(_current_state: int, _delta: float) -> int:
    return KEEP_CURRENT_STATE

func update_state(delta: float) -> void:
    var new_state = _get_next_state(state, delta)
    if new_state != KEEP_CURRENT_STATE:
        set_state(new_state)
        update_state(0)

func set_state(new_state: int) -> void:
    var old_state = state
    state = new_state
    _on_state_changed(state, old_state)
    emit_signal("state_changed", state, old_state)

func _on_state_changed(_new_state: int, _old_state: int) -> void:
    pass
