class_name G_Input
extends G.G_Object

var camera_node: Camera2D;
var camera_base_node: Node2D;

var ui_node: Control;

# signal input_handler_changed(handler: InputHandler, from: InputHandler);

# var input_handler: InputHandler;

# func set_input_handler(name: String = "") -> void:
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

