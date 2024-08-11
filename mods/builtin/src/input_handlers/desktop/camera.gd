class_name DesktopInputHandler_Camera
extends InputHandler.CameraModule

func _physics_process(_delta: float) -> void:
    if not Vars.core.is_in_game(): return
    if not get_from_controller: return
    var output = controller.camera_output
    if output.camera_world != world:
        world = output.camera_world
    transform = output.camera_transform
