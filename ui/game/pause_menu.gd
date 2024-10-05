class_name PauseMenu
extends PanelContainer

func toggle_pause_menu() -> void:
    if not visible:
        show_menu()
    else:
        hide_menu()

func _process(_delta: float) -> void:
    if not visible: return
    if not Vars.ui.focus.is_current_focused():
        Vars.ui.focus.set_current_focused(self)

func _on_game_ui_ui_hidden() -> void:
    hide_menu()

func _on_back_pressed() -> void:
    hide_menu()

func show_menu() -> void:
    visible = true
    Vars.ui.focus.set_current_focused(self)

func hide_menu() -> void:
    visible = false
    Vars.ui.focus.remove_focused_if_is(self)

func _on_pause_pressed() -> void:
    Vars.game.set_paused(not Vars.game.is_paused())

func _on_save_pressed() -> void:
    Vars.main.get_window_node("Saves").set_save_ui(true)
    Vars.main.open_window("Saves")

func _on_settings_pressed() -> void:
    Vars.main.open_window("Settings")

func _on_exit_pressed() -> void:
    Vars.game.reset_to_menu()
    hide_menu()

func _gui_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_open_pause_menu"):
        toggle_pause_menu()
