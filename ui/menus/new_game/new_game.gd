extends Window

var current_preset: Preset;
var PresetGroup = preload("res://ui/menus/new_game/preset_group.tscn");

func load_presets() -> void:
    for group in G.presets.preset_groups:
        var line = PresetGroup.instantiate();
        line.preset_group = group;
        line.pressed.connect(show_description)
        %PresetGroups.add_child(line);

func show_description(preset: Preset) -> void:
    current_preset = preset;
    %CurrentPresetName.text = tr(preset.get_tr_name());
    %ConfirmButton.disabled = false;
    for child in %PresetDescriptionBody.get_children():
        child.queue_free()
    preset._show_description(%PresetDescriptionBody);

func _on_search_text_changed(new_text: String) -> void:
    if new_text == "":
        for line in %PresetGroups.get_children():
            line.visible = true;
            for child in line.get_node("MarginContainer/PanelContainer/Presets").get_children():
                child.visible = true;
        return;
    for line in %PresetGroups.get_children():
        if line.get_node("Name").text.findn(new_text) != -1:
            line.visible = true;
            for child in line.get_node("MarginContainer/PanelContainer/Presets").get_children():
                child.visible = true;
            continue;
        var has_matched = false;
        for child in line.get_node("MarginContainer/PanelContainer/Presets").get_children():
            child.visible = child.text.findn(new_text) != -1;
            if child.visible:
                has_matched = true;
        line.visible = has_matched;

func _on_confirm_button_pressed() -> void:
    G.presets.load_preset(current_preset)
