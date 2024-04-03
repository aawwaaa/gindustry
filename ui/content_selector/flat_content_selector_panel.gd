class_name FlatContentSelectorPanel
extends ContentSelectorPanel

var group: ButtonGroup
var button_to_content: Dictionary = {}
var content_to_button: Dictionary = {}

@onready var container: HFlowContainer = %Container

func _load_contents() -> void:
    group = ButtonGroup.new()
    group.allow_unpress = true

    var sorted = Content.sort_content_list(content_type.contents)

    for content in sorted:
        var button = Button.new()
        button.icon = get_texture_for(content)
        button.toggle_mode = true
        button.button_group = group
        button.focus_mode = Control.FOCUS_NONE
        button.tooltip_text = "{localized} ( {full_id} )".format({
            localized = content.get_localized_name(),
            full_id = content.full_id
        })
        button.toggled.connect(_on_button_toggled)
        container.add_child(button)
        button_to_content[button] = content
        content_to_button[content] = button

func _on_button_toggled(pressed: bool) -> void:
    var button = group.get_pressed_button()
    if not button:
        selected_changed.emit(null)
        return
    selected_changed.emit(button_to_content[button])

func _set_selected(selected: Content) -> void:
    if not selected:
        var button = group.get_pressed_button()
        if not button: return
        button.button_pressed = false
        return
    content_to_button[selected].button_pressed = true

