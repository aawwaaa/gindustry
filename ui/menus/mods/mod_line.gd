extends HBoxContainer

signal toggled(info: ModInfo, enabled: bool);
signal pressed(info: ModInfo);

var mod_info: ModInfo;

func _on_button_pressed() -> void:
    emit_signal("pressed", mod_info);

func _on_enabled_pressed() -> void:
    emit_signal("toggled", mod_info, $Enabled.button_pressed);

func _ready() -> void:
    if not mod_info:
        return;
    $ModName.text = mod_info.name;
    $ModVersion.text = mod_info.display_version;
    $Enabled.button_pressed = mod_info.enabled;
