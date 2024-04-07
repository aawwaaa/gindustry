@tool
class_name GindustryTools_ContentsManager_ContentProperties
extends VBoxContainer

func _on_layer_tree_item_activated() -> void:
    pass

func _on_filter_text_changed(new_text: String) -> void:
    pass

func _on_add_element_pressed() -> void:
    pass

func _ready() -> void:
    %AddElement.icon = EditorInterface.get_editor_theme().get_icon(&"Add", &"EditorIcons")
