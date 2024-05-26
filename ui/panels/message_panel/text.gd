class_name MessagePanel_Text
extends PanelContainer

static var scene = load("res://ui/panels/message_panel/text.tscn")
static var text_duration_key = ConfigsGroup.ConfigKey.new("message_panel/text/text_duration", 3.0)

var showing: bool = false
var scene_tree_timer: SceneTreeTimer = null

func set_text(text: String) -> void:
    %Text.text = text

func show_text() -> void:
    show()
    showing = true

func hide_text() -> void:
    if scene_tree_timer == null: hide()
    showing = false

func show_short_time() -> void:
    show()
    scene_tree_timer = get_tree().create_timer(Vars.configs.k(text_duration_key))
    await scene_tree_timer.timeout
    scene_tree_timer = null
    if showing: return
    hide()
