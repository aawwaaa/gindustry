class_name DebugMenu_Basic
extends VBoxContainer

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
    # TODO change to InputHandler, add x, y rotation
    var speed = %CameraMoveSpeed.value * delta
    var plane_xy = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var z = Input.get_axis("move_down", "move_up")
    var vec = Vector3(plane_xy.x, z, plane_xy.y)
    if vec != Vector3.ZERO:
        vec = vec.normalized() * speed
    camera.transform = camera.transform.translated_local(vec)
    if Input.is_action_pressed("roll_clockwise"):
        camera.transform = camera.transform.rotated_local(Vector3.FORWARD, delta * (-PI))
    if Input.is_action_pressed("roll_counterclockwise"):
        camera.transform = camera.transform.rotated_local(Vector3.FORWARD, delta * (PI))

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

