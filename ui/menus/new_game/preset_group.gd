extends VBoxContainer

signal pressed(preset: Preset);

var preset_group: Presets.PresetGroup;

func _ready() -> void:
    %Name.text = preset_group.group_name;
    for preset in preset_group.presets:
        var button = Button.new();
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
        button.text = tr(preset.get_tr_name());
        button.pressed.connect(func():
            pressed.emit(preset)
        )
        %Presets.add_child(button)
