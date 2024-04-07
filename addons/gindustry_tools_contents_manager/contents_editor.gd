@tool
class_name GindustryTools_ContentsManager_ContentsEditor
extends VBoxContainer

const editor_scenes: Array[PackedScene] = [
    preload("res://addons/gindustry_tools_contents_manager/content_editors/content_list_editor.tscn"),
];
var editors: Array[GindustryTools_ContentsManager_ContentEditor] = []

var last_editor: GindustryTools_ContentsManager_ContentEditor

func open_content(content: Variant) -> void:
    if last_editor:
        print(last_editor)
        last_editor.clean_up()
        last_editor.hide_editor()
    for editor in editors:
        if not editor.applicatable(content): continue
        editor.show_editor()
        editor.load_content(content)
        last_editor = editor

func add_element_for(content: Variant) -> void:
    for editor in editors:
        if not editor.applicatable(content): continue
        editor.add_element_for(content)

func _exit_tree() -> void:
    for child in %Editors.get_children():
        child.queue_free()
    editors = []

func _ready() -> void:
    for scene in editor_scenes:
        var inst = scene.instantiate() as GindustryTools_ContentsManager_ContentEditor
        editors.append(inst)
        %Editors.add_child(inst)
        inst.clean_up()
        inst.hide_editor()
