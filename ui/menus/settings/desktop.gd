extends RefCounted

var group: SettingsUIGroup

func load() -> SettingsUIGroup:
    group = Settings.create("Settings_Desktop")
    
    var input = group.child_group("Settings_Desktop_Input")
    
    input.checkbox("Settings_Desktop_Input_FlipX", DesktopInputHandler_Movement.flip_x_key)
    input.checkbox("Settings_Desktop_Input_FlipY", DesktopInputHandler_Movement.flip_y_key)
    input.checkbox("Settings_Desktop_Input_SwapXY", DesktopInputHandler_Movement.swap_xy_key)
    var mouse_deadzone = input.number("Settings_Desktop_Input_MouseDeadzone", \
            DesktopInputHandler_Movement.mouse_deadzone_key)
    mouse_deadzone.validator = func(v): return v > 0
    var mouse_roll_duration = input.number("Settings_Desktop_Input_MouseRollDuration", \
            DesktopInputHandler_Movement.mouse_roll_duration_key)
    mouse_roll_duration.validator = func(v): return v > 0 and v < 1000

    return group
