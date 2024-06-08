class_name Vars_UI
extends Vars.Vars_Object

# move input.debug input.focus -> here
# create message_panel, console_panel

var debug: DebugMenu
var focus: FocusManager

var message_panel: MessagePanel
var console_panel: MessagePanel

func _ready() -> void:
    debug = DebugMenu.scene.instantiate()
    debug.name = "DebugMenu"
    add_child(debug)

    focus = FocusManager.new()
    focus.name = "FocusManager"
    add_child(focus)

    message_panel = MessagePanel.scene.instantiate()
    message_panel.name = "MessagePanel"
    message_panel.auto_complete_allowed = true
    message_panel.show_input() 
    add_child(message_panel)

    console_panel = MessagePanel.scene.instantiate()
    console_panel.name = "ConsolePanel"
    console_panel.set_prompt(">>>")
    # TODO connect -> console
    console_panel.hide()
    add_child(console_panel)
