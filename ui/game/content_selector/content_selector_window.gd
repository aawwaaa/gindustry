class_name ContentSelectorWindow
extends Window

signal submit(content: Content, amount: float)

var content_type_to_panel: Dictionary = {}
var current_type: ContentType = null

func _on_game_ui_contents_loaded() -> void:
    for content_type in Types.get_types(ContentType.TYPE).values() as Array[ContentType]:
        if not content_type.selector_panel: return
        var instance = content_type.selector_panel.instantiate()
        %Panelcontainer.add_child(instance)
        instance.selected_changed.connect(_on_instance_selected_changed)
        instance.load_contents()
        instance.hide_panel()

        content_type_to_panel[content_type] = instance

func show_content_type(content_type: ContentType) -> void:
    if current_type:
        content_type_to_panel[current_type].hide_panel()
    content_type_to_panel[content_type].show_panel()

func _on_amount_text_changed(new_text: String) -> void:
    pass # Replace with function body.

func _on_amount_slider_value_changed(value: float) -> void:
    pass # Replace with function body.

func _on_confirm_pressed() -> void:
    pass # Replace with function body.

func _on_cancel_pressed() -> void:
    pass # Replace with function body.

func _on_clear_pressed() -> void:
    pass # Replace with function body.
func _on_instance_selected_changed(selected: Content) -> void:
    pass
