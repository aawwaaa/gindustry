class_name DesktopInputHandler_Movement
extends InputHandlerModule


func _handle_process(_delta: float) -> void:
    if controller: update_move()

func update_move() -> void:
    controller.move_velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down");

