class_name Vars_UI
extends Vars.Vars_Object

var focus: FocusManager

var message_panel: MessagePanel
var console_panel: MessagePanel
var debug_menu: DebugMenu

var game_ui: GameUI
var input_ui: CanvasLayer

func _ready() -> void:
    focus = FocusManager.new()
    focus.name = "FocusManager"
    add_child(focus)

    debug_menu = DebugMenu.scene.instantiate()
    debug_menu.name = "DebugMenu"
    add_child(debug_menu)

    message_panel = MessagePanel.scene.instantiate()
    message_panel.name = "MessagePanel"
    message_panel.auto_complete_allowed = true
    message_panel.show_input() 
    add_child(message_panel)

    console_panel = MessagePanel.scene.instantiate()
    console_panel.name = "ConsolePanel"
    console_panel.set_prompt(">>>")
    # TODO connect -> console_panel
    console_panel.hide()
    add_child(console_panel)

    input_ui = CanvasLayer.new()
    input_ui.layer = 8
    input_ui.name = "InputUI"
    add_child(input_ui)

    game_ui = GameUI.scene.instantiate()
    game_ui.name = "GameUI"
    add_child(game_ui)
