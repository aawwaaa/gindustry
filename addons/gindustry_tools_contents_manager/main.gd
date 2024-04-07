@tool
class_name GindustryTools_ContentsManager_Main
extends EditorPlugin

static var main_panel: GindustryTools_ContentsManager_MainPanel
static var tree: GindustryTools_ContentsManager_ContentsTree
static var content_properties: GindustryTools_ContentsManager_ContentProperties

func _enable_plugin() -> void:
    add_tool_menu_item("Reload", func():
        var last_visible = main_panel.visible
        unload_plugin()
        load_plugin()
        _make_visible(last_visible)
    )
    tree = GindustryTools_ContentsManager_ContentsTree.new()
    tree.init()
    Engine.register_singleton("ContentsTree", tree)

    load_plugin()

func load_plugin() -> void:
    main_panel = load("res://addons/gindustry_tools_contents_manager/main_panel.tscn").instantiate()
    EditorInterface.get_editor_main_screen().add_child(main_panel)
    main_panel.set_tree(tree)
    main_panel.hide()
    content_properties = load("res://addons/gindustry_tools_contents_manager/content_properties.tscn").instantiate()
    content_properties.name = "ContentProperties"
    content_properties.hide()

func unload_plugin() -> void:
    main_panel.clear_tree()
    main_panel.queue_free()

    content_properties.queue_free()

func _disable_plugin() -> void:
    unload_plugin()

    remove_tool_menu_item("Reload")
    Engine.unregister_singleton("ContentsTree")

func _has_main_screen() -> bool:
    return true

func _get_plugin_name() -> String:
    return "ContentsManager"

func _make_visible(visible: bool) -> void:
    main_panel.visible = visible
    if visible:
        add_control_to_dock(DOCK_SLOT_LEFT_UR, content_properties)
        content_properties.visible = true
    else:
        remove_control_from_docks(content_properties)

func _save_external_data() -> void:
    tree.save_content_lists()
