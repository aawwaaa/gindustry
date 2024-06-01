class_name Loading_LogLine
extends HBoxContainer

static var colors: Dictionary = {
    Log.LogLevel.INFO: Color.WHITE,
    Log.LogLevel.WARN: Color.LIGHT_YELLOW,
    Log.LogLevel.ERROR: Color.RED,
    Log.LogLevel.DEBUG: Color.LIGHT_CYAN
}
static var settings: Dictionary = {}

static func _static_init() -> void:
    for k in colors:
        var setting = LabelSettings.new()
        setting.font_color = colors[k]
        settings[k] = setting

@onready var source_label: Label = %Source
@onready var level_label: Label = %Level
@onready var message_label: Label = %Message

func apply(source: String, level: Log.LogLevel, message: String) -> void:
    source_label.text = source
    level_label.text = tr(Log.log_levels[level])
    message_label.text = message
    level_label.label_settings = settings[level]

