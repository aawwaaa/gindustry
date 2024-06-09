class_name Vars_Input
extends Vars.Vars_Object

const INPUT_HANDLER_CONFIG = "input/input_handler"
static var input_handler_key = ConfigsGroup.ConfigKey.new(INPUT_HANDLER_CONFIG, "")

var camera: CameraController;

signal input_handler_changed(handler: InputHandler, from: InputHandler);

var input_handler: InputHandler;

func set_input_handler(handler_name: String = "") -> void:
    if handler_name != "":
        Vars.configs.pk(input_handler_key, handler_name)
        Vars.configs.save_configs()
    else:
        handler_name = Vars.configs.k(input_handler_key)
    var old = input_handler if input_handler else null
    if input_handler:
        input_handler.exit_game()
        input_handler.remove_ui(Vars.ui.input_ui)
    input_handler = InputHandler.input_handlers[handler_name].create.call() \
            if InputHandler.input_handlers.has(handler_name) else null
    if input_handler:
        input_handler.name = handler_name
        add_child(input_handler)
        input_handler.add_ui(Vars.ui.input_ui)
    input_handler_changed.emit(input_handler, old)
    if input_handler and old:
        input_handler.extend_from(old)
    if old:
        old.queue_free()
    if Vars.core.is_in_game():
        input_handler.enter_game()

func _on_state_changed(state: Vars_Core.State, from: Vars_Core.State) -> void:
    if state == Vars_Core.State.IN_GAME:
        if input_handler: input_handler.enter_game()
    if from == Vars_Core.State.IN_GAME:
        if input_handler: input_handler.exit_game()

func get_default_input_handler() -> String:
    return "desktop"
   
func _ready() -> void:
    camera = CameraController.new()
    camera.name = "CameraController"
    add_child(camera)

    Vars.core.state.state_changed.connect(_on_state_changed)

