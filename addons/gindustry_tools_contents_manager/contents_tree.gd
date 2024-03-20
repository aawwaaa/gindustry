@tool
class_name GindustryTools_ContentsManager_ContentsTree
extends Tree

var editor: GindustryTools_ContentsManager_ContentsEditor

class ContentListItem extends RefCounted:
    var content_list: ContentList
    var menu_id: int
    var child_types: Dictionary = {}
    var child_contents: Dictionary = {}

    func add_to_tree(tree: GindustryTools_ContentsManager_ContentsTree) -> TreeItem:
        var item = tree.root.create_item()
        item.set_text(content_list.resource_path)
        return item

var root: TreeItem

var content_lists: Array[ContentListItem] = []
var tree_items: Dictionary = {}

func load_content_lists() -> void:
    var paths = ProjectSettings.get_setting("gindustry_tools/contents_manager/content_lists", [])
    for path in paths:
        var list = load(path)
        var item = ContentListItem.new()
        item.content_list = list
        var tree_item = item.add_to_tree(self)
        content_lists.append(item)
        tree_items[tree_item.id] = item

func save_content_lists() -> void:
    var paths = []
    for item in content_lists:
        paths.append(item.content_list.resource_path)
    ProjectSettings.set_setting("gindustry_tools/contents_manager/content_lists", paths)

func init() -> void:
    root = create_item()
    root.set_text(0, "ContentLists")

    load_content_lists()

    item_activated.connect(_on_item_activated)

func _on_item_activated() -> void:
    var selected = get_selected()
    if selected == root:
        editor.open_content_lists()
        return
    var item = tree_items[selected.id]
    editor.open_content(item)
