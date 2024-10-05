class_name FocusManager
extends Node

signal focus_changed(node: Node, from: Node)

var windows: Array[LayerWindow]:
    get: return LayerWindow.windows

var current_focused: Node:
    set = set_current_focused
var alter_focused: Node = null;

func is_focused(node: Node) -> bool:
    return node == current_focused

func set_focused(node: Node) -> void:
    if node == null:
        current_focused = alter_focused;
        alter_focused = null
        return
    if current_focused == node: return
    alter_focused = current_focused
    current_focused = node

func is_current_focused() -> bool:
    return current_focused != null

func remove_focused_if_is(node: Node) -> void:
    if current_focused == node:
        current_focused = alter_focused
        alter_focused = null

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var focused = get_viewport().gui_get_focus_owner()
        if focused: focused.release_focus()
        set_focused(null)

func set_current_focused(node: Node) -> void:
    if is_focused(node): return
    alter_focused = current_focused
    current_focused = node
    focus_changed.emit(node, alter_focused)
    Utils.signal_dynamic_connect(node, alter_focused, \
            "visibility_changed", _on_current_focused_visibility_changed)

func _on_current_focused_visibility_changed() -> void:
    if not current_focused.visible:
        set_focused(null)
