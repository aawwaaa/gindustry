class_name PauseMenu
extends PanelContainer

func toggle_pause_menu() -> void:
    visible = not visible;

func _on_game_ui_ui_hidden() -> void:
    visible = false

func _on_back_pressed() -> void:
    visible = false

func _on_pause_pressed() -> void:
    G.game.set_paused(not G.game.is_paused())

func _on_save_pressed() -> void:
    G.main.get_window_node("Saves").set_save_ui(true)
    G.main.open_window("Saves")

func _on_settings_pressed() -> void:
    G.main.open_window("Settings")

func _on_exit_pressed() -> void:
    visible = false
    G.game.back_to_menu()
