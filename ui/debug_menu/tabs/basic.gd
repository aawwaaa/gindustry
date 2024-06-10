class_name DebugMenu_Basic
extends VBoxContainer

const CAMERA_ROLL_SPEED = 0.4 * TAU

var menu: DebugMenu
var free_camera: bool = false

@onready var camera: CameraController = %Camera

func _on_free_camera_toggled(toggled_on: bool) -> void:
    free_camera = toggled_on
    Vars.input.camera.active = not free_camera
    camera.active = free_camera
    camera.set_world(Vars.worlds.current_toggled_world)
    %ToggleTo.disabled = not free_camera

func _physics_process(delta: float) -> void:
    if free_camera: process_free_camera(delta)
    update_camera_transform()

func process_free_camera(delta: float) -> void:
    var speed = %CameraMoveSpeed.value
    var input = Vars.input.input_handler
    var move = InputHandler.MovementModule.get_move_velocity_for(input)
    var roll = InputHandler.MovementModule.get_roll_velocity_for(input)
    camera.transform = camera.transform.translated_local(move * delta * speed)
    for axis_id in [1, 0, 2]:
        var axis = [Vector3.LEFT, Vector3.UP, Vector3.FORWARD][axis_id]
        camera.transform = camera.transform.rotated_local(axis, roll[axis_id] * delta * 0.5 * TAU)

func update_camera_transform() -> void:
    var camera_controller = Vars.input.camera if Vars.input.camera.active \
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

