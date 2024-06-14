class_name DesktopInputHandler_Menu
extends InputHandler.MenuModule

func _handle_input(input: InputEvent) -> bool:
    if input.is_action_pressed("ui_open_pause_menu"):
        Vars.ui.game_ui.pause_menu.show_menu()
        return true
    return false
