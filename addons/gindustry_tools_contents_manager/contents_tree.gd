@tool
class_name GindustryTools_ContentsManager_ContentsTree
extends Tree

var editor: GindustryTools_ContentsManager_ContentsEditor

class ContentTreeItem extends RefCounted:
    static var tree: GindustryTools_ContentsManager_ContentsTree
    var parent: TreeItem
    var item: TreeItem
    var menu_id: int

    var data: Variant
    var name: String

    func add_to_tree() -> TreeItem:
        item = parent.create_child()
        menu_id = item.get_index()
        item.set_text(0, name)
        tree.tree_items[menu_id] = self
        return item

    func create_child() -> ContentTreeItem:
        var child = ContentTreeItem.new()
        child.parent = item
        return child

    func remove() -> void:
        tree.tree_items.erase(self)
        if self in tree.content_lists:
            tree.content_lists.erase(self)
        item.queue_free()

var root: TreeItem
var root_item: ContentTreeItem

var content_lists: Array[ContentTreeItem] = []
var tree_items: Dictionary = {}

func load_content_lists() -> void:
    var paths = ProjectSettings.get_setting("gindustry_tools/contents_manager/content_lists", [])
    for path in paths:
        var list = load(path)
        var item = root_item.create_child()
        item.data = list
        item.name = path
        var tree_item = item.add_to_tree()
        content_lists.append(item)

func save_content_lists() -> void:
    var paths = []
    for item in content_lists:
        paths.append(item.data.resource_path)
    ProjectSettings.set_setting("gindustry_tools/contents_manager/content_lists", paths)

func init() -> void:
    root = create_item()
    root_item = ContentTreeItem.new()
    root.set_text(0, "ContentLists")
    root_item.menu_id = 0
    root_item.name = "ContentLists"
    root_item.data = self
    tree_items[0] = root_item

    load_content_lists()

    item_activated.connect(_on_item_activated)

func _on_item_activated() -> void:
    editor.open_content(get_selected_data())

func get_selected_data() -> Variant:
    var selected = get_selected()
    var item = tree_items[selected.get_index()]
    return item.data

func apply_filter(text: String, item = root) -> void:
    item.visible = text == "" or item.get_text(0).to_lower().contains(text)
    for child in item.get_children():
        apply_filter(text, child)
