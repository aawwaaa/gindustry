class_name GindustryTools_ContentsManager_ContentEditor
extends VBoxContainer

var tree: GindustryTools_ContentsManager_ContentsTree:
    get: return GindustryTools_ContentsManager_Main.tree
var editing: Variant

func _show_editor() -> void:
    show()

func _hide_editor() -> void:
    hide()

func _load_content(content: Variant) -> void:
    editing = content

func _clean_up() -> void:
    editing = null

func _applicatable(content: Variant) -> bool:
    return false

func _add_element_for(content: Variant) -> void:
    pass

func show_editor() -> void:
    _show_editor()

func hide_editor() -> void:
    _hide_editor()

func load_content(content: Variant) -> void:
    _load_content(content)

func clean_up() -> void:
    _clean_up()
    
func applicatable(content: Variant) -> bool:
    return _applicatable(content)

func add_element_for(content: Variant) -> void:
    _add_element_for(content)
