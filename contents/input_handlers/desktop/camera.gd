class_name DesktopInputHandler_Camera
extends InputHandlerModule

var camera_position: Vector2;
var camera_rotation: float;
var camera_zoom: float = 1;

func _handle_process(_delta: float) -> void:
    if target: update_camera()

func _handle_unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton: handle_unhandled_input_event_mouse_button(event)

func update_camera() -> void:
    camera_position = controller.get_target_attribute("position")
    camera_rotation = controller.get_target_attribute("rotation")
    if camera_position != null:
        Game.camera_base_node.position = camera_position;
        Game.camera_base_node.rotation = camera_rotation;
    Game.camera_node.zoom = Game.camera_node.zoom.lerp(Vector2(camera_zoom, camera_zoom), 0.15);

func handle_camera_zoom(event: InputEventMouseButton) -> void:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
        camera_zoom *= 1.1
    if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        camera_zoom /= 1.1

