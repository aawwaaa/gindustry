class_name DesktopInputHandler_Movement
extends InputHandler.MovementModule

const FLIP_X_CONFIG: StringName = &"desktop/input/flip_x"
const FLIP_Y_CONFIG: StringName = &"desktop/input/flip_y"
const SWAP_XY_CONFIG: StringName = &"desktop/input/swap_xy"
const MOUSE_DEADZONE_CONFIG: StringName = &"desktop/input/mouse_deadzone"
const MOUSE_FACTOR_CONFIG: StringName = &"desktop/input/mouse_factor"
const MOUSE_ROLL_DURATION_CONFIG: StringName = &"desktop/input/mouse_roll_duration"
const KEEP_Y_UP_IN_GRAVITY_CONFIG: StringName = &"desktop/input/keep_y_up_in_gravity"
const KEEP_Y_UP_IN_GRAVITY_RATE_CONFIG: StringName = &"desktop/input/keep_y_up_in_gravity_rate"
const ANTI_LINEAR_VELOCITY_CONFIG: StringName = &"desktop/input/anti_linear_velocity"

static var flip_x_key = ConfigsGroup.ConfigKey.new(FLIP_X_CONFIG, false)
static var flip_y_key = ConfigsGroup.ConfigKey.new(FLIP_Y_CONFIG, false)
static var swap_xy_key = ConfigsGroup.ConfigKey.new(SWAP_XY_CONFIG, true)
static var mouse_deadzone_key = ConfigsGroup.ConfigKey.new(MOUSE_DEADZONE_CONFIG, 4)
static var mouse_factor_key = ConfigsGroup.ConfigKey.new(MOUSE_FACTOR_CONFIG, 0.02)
static var mouse_roll_duration_key = ConfigsGroup.ConfigKey.new(MOUSE_ROLL_DURATION_CONFIG, 10)
static var keep_y_up_in_gravity_key = ConfigsGroup.ConfigKey.new(KEEP_Y_UP_IN_GRAVITY_CONFIG, true)
static var keep_y_up_in_gravity_rate_key = ConfigsGroup.ConfigKey.new(KEEP_Y_UP_IN_GRAVITY_RATE_CONFIG, 0.3 * 9.8)
static var anti_linear_velocity_key = ConfigsGroup.ConfigKey.new(ANTI_LINEAR_VELOCITY_CONFIG, true)

const INPUT_MOVE_FORWARD: StringName = &"move_forward"
const INPUT_MOVE_BACKWARD: StringName = &"move_backward"
const INPUT_MOVE_LEFT: StringName = &"move_left"
const INPUT_MOVE_RIGHT: StringName = &"move_right"
const INPUT_MOVE_UP: StringName = &"move_up"
const INPUT_MOVE_DOWN: StringName = &"move_down"
const INPUT_ROLL_CLOCKWISE: StringName = &"roll_clockwise"
const INPUT_ROLL_COUNTERCLOCKWISE: StringName = &"roll_counterclockwise"
const ACTIONS: Array[StringName] = [
    INPUT_MOVE_FORWARD,
    INPUT_MOVE_BACKWARD,
    INPUT_MOVE_LEFT,
    INPUT_MOVE_RIGHT,
    INPUT_MOVE_UP,
    INPUT_MOVE_DOWN,
    INPUT_ROLL_CLOCKWISE,
    INPUT_ROLL_COUNTERCLOCKWISE,
]
const ACTION_TO_MOVEMENT: Array[Vector3] = [
    Vector3.FORWARD,
    Vector3.BACK,
    Vector3.LEFT,
    Vector3.RIGHT,
    Vector3.UP,
    Vector3.DOWN,
    Vector3.ZERO,
    Vector3.ZERO,
]
const ACTION_TO_ROLL: Array[Vector3] = [
    Vector3.ZERO,
    Vector3.ZERO,
    Vector3.ZERO,
    Vector3.ZERO,
    Vector3.ZERO,
    Vector3.ZERO,
    Vector3(0, 0, -10),
    Vector3(0, 0, 10),
]

const HUGE = 100

var space_axis_panel: SpaceAxisPanel

var current_pressed: Array[bool] = [false, false, false, false, false, false, false, false]
var mouse_velocity: Vector2 = Vector2.ZERO
var mouse_update: int = 0
var mouse_capture_timer: float = 0

func _ready() -> void:
    Vars.ui.focus.focus_changed.connect(_on_focus_changed)

func _handle_input(input: InputEvent) -> bool:
    if not Vars.core.is_in_game(): return false
    if input is InputEventKey:
        if input.echo: return false
        for action in ACTIONS:
            if not input.is_action(action): continue
            var index = ACTIONS.find(action)
            if input.is_action_pressed(action) and not current_pressed[index]:
                current_pressed[index] = true
                return true
            if not input.is_action_pressed(action) and current_pressed[index]:
                current_pressed[index] = false
                return true
    if input is InputEventMouseMotion:
        mouse_velocity = input.relative
        mouse_update = Time.get_ticks_msec()
        return true
    return false

func _on_focus_changed(_1, _2) -> void:
    if not Vars.core.is_in_game(): return
    if Vars.ui.focus.is_current_focused():
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        mouse_velocity = Vector2.ZERO
        mouse_capture_timer = Time.get_ticks_msec()
    elif mouse_capture_timer + 20 < Time.get_ticks_msec():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _enter_game() -> void:
    if not Vars.ui.focus.is_current_focused():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    space_axis_panel.visible = true

func _exit_game() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    current_pressed.fill(false)
    mouse_velocity = Vector2.ZERO
    space_axis_panel.visible = false

func _get_input_move_velocity() -> Vector3:
    var vel = Vector3.ZERO
    for index in current_pressed.size():
        if current_pressed[index]:
            vel += ACTION_TO_MOVEMENT[index]
    return vel

func _get_move_velocity() -> Vector3:
    var vel = get_input_move_velocity()
    vel += get_fix_move_velocity_anti_linear_velocity()
    return vel

func get_fix_move_velocity_anti_linear_velocity() -> Vector3:
    if not Vars.configs.k(anti_linear_velocity_key): return Vector3.ZERO
    var vel = controller.movement.entity_linear_velocity \
            + controller.movement.entity_gravity
    var mass = controller.movement.entity_mass
    var fix = - (vel * mass if vel != Vector3.ZERO else Vector3.ZERO)
    fix = controller.movement.normalize_force(fix)
    return fix

func _get_input_roll_velocity() -> Vector3:
    var vel = Vector3.ZERO
    for index in current_pressed.size():
        if current_pressed[index]:
            vel += ACTION_TO_ROLL[index]
    if mouse_update + Vars.configs.k(mouse_roll_duration_key) > Time.get_ticks_msec() \
            and mouse_velocity.length_squared() > Vars.configs.k(mouse_deadzone_key) ** 2:
        var x = mouse_velocity.x * (-1 if Vars.configs.k(flip_x_key) else 1)
        var y = mouse_velocity.y * (-1 if Vars.configs.k(flip_y_key) else 1)
        vel += (Vector3(x, y, 0) if not Vars.configs.k(swap_xy_key) else Vector3(y, x, 0)) \
                * Vars.configs.k(mouse_factor_key)
    return vel

func _get_roll_velocity() -> Vector3:
    var vel = get_input_roll_velocity()
    vel += get_fix_roll_velocity_keep_y_up()
    vel += get_fix_roll_velocity_anti_angular_velocity()
    return vel

func get_fix_roll_velocity_anti_angular_velocity() -> Vector3:
    var fix = - (controller.movement.entity_angular_velocity \
            if controller.movement.entity_angular_velocity != Vector3.ZERO else Vector3.ZERO)
    return fix

func get_fix_roll_velocity_keep_y_up() -> Vector3:
    if not Vars.configs.k(keep_y_up_in_gravity_key): return Vector3.ZERO
    # var gravity = controller.movement.entity_gravity
    var gravity = controller.movement.entity_basis.inverse() * Vector3(0, -9.8, 0)
    if gravity.length_squared() < Vars.configs.k(keep_y_up_in_gravity_rate_key) ** 2:
        return Vector3.ZERO
    var local_up = -gravity.normalized()
    var local_up_projected = Vector2(local_up.x, local_up.y).normalized()

    var angle_z = local_up_projected.angle_to(Vector2.UP)
    var s = signi(angle_z)
    angle_z = s * (PI - abs(angle_z))
    var vel = angle_z
    
    return Vector3(0, 0, vel)

func _physics_process(_delta: float) -> void:
    if not Vars.core.is_in_game(): return
    if controller and sync_to_controller:
        controller.movement.input_move_velocity = get_move_velocity()
        controller.movement.input_roll_velocity = get_roll_velocity()
    if space_axis_panel:
        space_axis_panel.basis = controller.movement.entity_basis.inverse()

func _add_ui(node: Control) -> void:
    space_axis_panel = SpaceAxisPanel.scene.instantiate()
    space_axis_panel.name = "SpaceAxisPanel"
    space_axis_panel.visible = false
    node.add_child(space_axis_panel)

func _remove_ui(node: Control) -> void:
    node.remove_child(space_axis_panel)
    space_axis_panel.queue_free()
