@tool
class_name GindustryTools
extends EditorPlugin

var inspector: EditorInspectorPlugin

func _enter_tree() -> void:
    inspector = GindustryTools_Inspector.new()
    add_inspector_plugin(inspector)

func _exit_tree() -> void:
    remove_inspector_plugin(inspector)
