class_name DesktopInputHandler
extends InputHandler

static var meta: InputHandlerMeta
static func load_handler() -> void:
    meta = InputHandlerMeta.new({
        "id": "desktop",
        "create": func(): return DesktopInputHandler.new(),
        "tr_name": "builtin_input_handler_desktop",
    })

    InputHandler.register_input_handler(meta)

var menu: DesktopInputHandler_Menu
var movement: DesktopInputHandler_Movement

func _ready() -> void:
    menu = DesktopInputHandler_Menu.new()
    add_module(menu)

    movement = DesktopInputHandler_Movement.new()
    add_module(movement)

func _input(event: InputEvent) -> void:
    if Vars.ui.focus.is_current_focused(): return
    push_input(event)

func _unhandled_input(event: InputEvent) -> void:
    if Vars.ui.focus.is_current_focused(): return
    push_unhandled_input(event)
