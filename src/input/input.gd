class_name Vars_Input
extends Vars.Vars_Object

const INPUT_HANDLER_CONFIG = "input/input_handler"
static var input_handler_key = ConfigsGroup.ConfigKey.new(INPUT_HANDLER_CONFIG, "")

var ui_node: Control;

var camera: CameraController;

# signal input_handler_changed(handler: InputHandler, from: InputHandler);

# var input_handler: InputHandler;

func set_input_handler(_name: String = "") -> void:
    pass
#     if name != "":
#         configs.p("input-handler", name)
#         save_configs()
#     else:
#         name = configs.g("input-handler", main.get_default_input_handler())
#     var old = input_handler if input_handler else null
#     if input_handler:
#         input_handler._unload_ui(game_ui_input_handler)
#     input_handler = InputHandler.input_handlers[name].input_handler.new()
#     add_child(input_handler)
#     input_handler._load_ui(game_ui_input_handler)
#     input_handler_changed.emit(input_handler, old)
#     if old:
#         input_handler.extend_properties(old)
#         old.queue_free()

func _ready() -> void:
    camera = CameraController.new()
    camera.name = "CameraController"
    add_child(camera)

