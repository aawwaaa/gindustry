@tool
class_name GindustryTools_Inspector
extends EditorInspectorPlugin

class Property extends EditorProperty:
    var label_node: Label

    func _ready() -> void:
        label_node = Label.new()
        add_child(label_node)

    func _set_read_only(read_only: bool) -> void:
        pass

    func _update_property() -> void:
        label = get_edited_property()
        label_node.text = get_edited_property()

func _can_handle(object: Object) -> bool:
    return object is Node

func _parse_begin(object: Object) -> void:
    add_property_editor("Hello world!", Property.new())

