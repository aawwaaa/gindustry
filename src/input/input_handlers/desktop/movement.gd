class_name DesktopInputHandler_Movement
extends InputHandler.MovementModule

const INPUT_MOVE_FORWARD: StringName = &"move_forward"
const INPUT_MOVE_BACKWARD: StringName = &"move_backward"
const INPUT_MOVE_LEFT: StringName = &"move_left"
const INPUT_MOVE_RIGHT: StringName = &"move_right"
const INPUT_ROLL_CLOCKWISE: StringName = &"roll_clockwise"
const INPUT_ROLL_COUNTERCLOCKWISE: StringName = &"roll_counterclockwise"
const ACTIONS: Array[StringName] = [
    INPUT_MOVE_FORWARD,
    INPUT_MOVE_BACKWARD,
    INPUT_MOVE_LEFT,
    INPUT_MOVE_RIGHT,
    INPUT_ROLL_CLOCKWISE,
    INPUT_ROLL_COUNTERCLOCKWISE,
]
const ACTION_TO_MOVEMENT: Array[Vector3] = [
    Vector3.FORWARD,
    Vector3.BACK,
    Vector3.LEFT,
    Vector3.RIGHT,
    Vector3.ZERO,
    Vector3.ZERO,
]
const ACTION_TO_ROLL: Array[Vector3] = [
    Vector3.ZERO,
    Vector3.ZERO,
    Vector3.ZERO,
    Vector3.ZERO,
    Vector3(0, 0, -1),
    Vector3(0, 0, 1),
]

var current_pressed: Array[bool] = [false, false, false, false, false, false]
var mouse_velocity: Vector2 = Vector2.ZERO

func _handle_input(input: InputEvent) -> bool:
    if not Vars.core.is_in_game(): return false
    for action in ACTIONS:
        var index = ACTIONS.find(action)
        if input.is_action_pressed(action) and not current_pressed[index]:
            current_pressed[index] = true
            return true
        if not input.is_action_pressed(action) and current_pressed[index]:
            current_pressed[index] = false
            return true
    if input is InputEventMouseMotion:
        mouse_velocity = input.relative
        var window_size = DisplayServer.window_get_size()
        DisplayServer.warp_mouse(Vector2i(window_size.x / 2, window_size.y / 2))
        return true
    return false

func _exit_game() -> void:
    current_pressed.fill(false)
    mouse_velocity = Vector2.ZERO

func _get_move_velocity() -> Vector3:
    var vel = Vector3.ZERO
    for index in current_pressed.size():
        if current_pressed[index]:
            vel += ACTION_TO_MOVEMENT[index]
    if vel != Vector3.ZERO: vel = vel.normalized()
    return vel

func _get_roll_velocity() -> Vector3:
    var vel = Vector3.ZERO
    for index in current_pressed.size():
        if current_pressed[index]:
            vel += ACTION_TO_ROLL[index]
    vel += Vector3(mouse_velocity.x, mouse_velocity.y, 0)
    if vel != Vector3.ZERO: vel = vel.normalized()
    return vel
