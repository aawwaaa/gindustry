@tool
class_name GindustryTools_ContentsManager_MainPanel
extends Control

func set_tree(tree: GindustryTools_ContentsManager_ContentsTree) -> void:
    %TreeContainer.add_child(tree)
    tree.editor = %ContentsEditor

func clear_tree() -> void:
    for child in %TreeContainer.get_children():
        child.editor = null
        %TreeContainer.remove_child(child)
