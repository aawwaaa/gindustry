class_name MessagePanel_Message
extends PanelContainer

static var scene = load("res://ui/panels/message_panel/message.tscn")
static var message_duration_key = ConfigsGroup.ConfigKey.new("message_panel/message/message_duration", 3.0)

var showing: bool = false
var scene_tree_timer: SceneTreeTimer = null

func set_message(message: String) -> void:
    %Label.text = message

func show_message() -> void:
    show()
    showing = true

func hide_message() -> void:
    if scene_tree_timer == null: hide()
    showing = false

func show_short_time() -> void:
    show()
    scene_tree_timer = get_tree().create_timer(Vars.configs.k(message_duration_key))
    await scene_tree_timer.timeout
    scene_tree_timer = null
    if showing: return
    hide()
