extends GA_Preset

func _Data() -> void:
    Id = "NetTest"

func _Visible() -> bool:
    return false

func _PresetInit() -> void:
    Source.logger.Info("NetTestPreset")
