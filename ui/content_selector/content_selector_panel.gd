class_name ContentSelectorPanel
extends VBoxContainer

signal selected_changed(selected: Content)

var content_type: ContentType

func _load_contents() -> void:
    pass

func _set_selected(_selected: Content) -> void:
    pass

func _get_texture_for(content: Content) -> Texture2D:
    return content.get_icon()

func load_contents() -> void:
    _load_contents()

func hide_panel() -> void:
    hide()

func show_panel() -> void:
    show()

func set_selected(selected: Content) -> void:
    _set_selected(selected)

func get_texture_for(content: Content) -> Texture2D:
    return _get_texture_for(content)
