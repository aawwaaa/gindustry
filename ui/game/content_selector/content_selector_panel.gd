class_name ContentSelectorPanel
extends VBoxContainer

signal selected_changed(selected: Content)

func _load_contents() -> void:
    pass

func _set_selected(selected: Content) -> void:
    pass

func load_contents() -> void:
    _load_contents()

func hide_panel() -> void:
    hide()

func show_panel() -> void:
    show()

func set_selected(selected: Content) -> void:
    _set_selected(selected)
