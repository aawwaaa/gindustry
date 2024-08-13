class_name DebugMenu_Basic
extends VBoxContainer

const CAMERA_ROLL_SPEED = 0.4 * TAU

var menu: DebugMenu
var free_camera: bool = false

var capture_input: bool = true

var camera_module: InputHandler.CameraModule:
    get: return Vars.input.input_handler.get_module(InputHandler.CameraModule.TYPE) \
            if Vars.input and Vars.input.input_handler else null
var movement_module: InputHandler.MovementModule:
    get: return Vars.input.input_handler.get_module(InputHandler.MovementModule.TYPE) \
            if Vars.input and Vars.input.input_handler else null
@onready var camera: CameraController = %Camera

func _on_free_camera_toggled(toggled_on: bool) -> void:
    free_camera = toggled_on
    camera_module.camera.active = not free_camera
    camera.active = free_camera
    camera.set_world(Vars.worlds.current_toggled_world)
    if movement_module:
        movement_module.sync_to_controller = not free_camera or not capture_input
    %ToggleTo.disabled = not free_camera
    %CaptureInput.disabled = not free_camera

func _on_capture_input_toggled(toggled_on: bool) -> void:
    capture_input = toggled_on
    if not free_camera: return
    if movement_module:
        movement_module.sync_to_controller = not free_camera or not capture_input

func _physics_process(delta: float) -> void:
    if free_camera: process_free_camera(delta)
    update_camera_transform()

func process_free_camera(delta: float) -> void:
    if not movement_module or not capture_input: return
    var speed = %CameraMoveSpeed.value
    var move = movement_module.get_input_move_velocity() if movement_module else Vector3.ZERO
    var roll = movement_module.get_input_roll_velocity() if movement_module else Vector3.ZERO
    move = move.normalized() if move.is_finite() \
            else move.clamp(Vector3.ONE * -1, Vector3.ONE).normalized()
    roll = roll.normalized() if roll.is_finite() \
            else roll.clamp(Vector3.ONE * -1, Vector3.ONE).normalized()
    camera.transform = camera.transform.translated_local(move * delta * speed)
    for axis_id in [1, 0, 2]:
        var axis = [Vector3.LEFT, Vector3.UP, Vector3.FORWARD][axis_id]
        camera.transform = camera.transform.rotated_local(axis, roll[axis_id] * delta * 0.5 * TAU)

func update_camera_transform() -> void:
    var camera_controller = camera_module.camera if camera_module and camera_module.camera.active \
            else camera
    if not camera_controller.active:
        %CameraTransform.text = "<unknown>"
        return
    %CameraTransform.text = """CameraTransform: {
    Origin: {origin}
}""".format({origin = camera_controller.transform.origin})

func _on_toggle_to_pressed() -> void:
    var selected = %RootWorlds.get_current_selected()
    if selected: selected.toggle_to()



