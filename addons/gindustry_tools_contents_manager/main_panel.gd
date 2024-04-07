@tool
class_name GindustryTools_ContentsManager_MainPanel
extends Control

var tree: GindustryTools_ContentsManager_ContentsTree

func set_tree(tree: GindustryTools_ContentsManager_ContentsTree) -> void:
    %TreeContainer.add_child(tree)
    tree.editor = %ContentsEditor
    self.tree = tree

func clear_tree() -> void:
    for child in %TreeContainer.get_children():
        child.editor = null
        %TreeContainer.remove_child(child)

func _on_add_element_pressed() -> void:
    %ContentsEditor.add_element_for(tree.get_selected_data())

func _on_filter_text_changed(new_text: String) -> void:
    tree.apply_filter(new_text.to_lower())

func _ready() -> void:
    %AddElement.icon = EditorInterface.get_editor_theme().get_icon(&"Add", &"EditorIcons")
