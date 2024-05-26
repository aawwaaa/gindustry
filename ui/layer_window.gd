class_name LayerWindow
extends CanvasLayer

signal close_requested()

const CLOSE_ICON = preload("res://assets/ui/icons/cross.tres")

static var windows: Array[LayerWindow] = []

var panel: PanelContainer
var title_button: Button
var close_button: Button

@export var title: String:
    set = set_title
@export var size: Vector2:
    set = set_size

"""
LayerWindow - Layer
    | VBoxContainer
    |   | HBoxContainer
    |   |   | Button - Drag(title)
    |   |   | Button - Close
    |   | Container
    |   |   | Body
"""

func create_nodes() -> Container:
    panel = PanelContainer.new()
    panel.focus_mode = Control.FOCUS_CLICK
    add_child(panel)

    var box = VBoxContainer.new()
    panel.add_child(box)

    var hbox = HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.custom_minimum_size = Vector2(0, 32)
    hbox.scale = Vector2(1, 0.5)
    box.add_child(hbox)

    title_button = Button.new()
    title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_button.gui_input.connect(_on_title_button_gui_input)
    title_button.focus_mode = Control.FOCUS_NONE
    hbox.add_child(title_button)

    close_button = Button.new()
    close_button.custom_minimum_size = Vector2(32, 32)
    close_button.icon = CLOSE_ICON
    close_button.pressed.connect(_on_close_pressed)

    hbox.add_child(close_button)

    var container = Container.new()
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(container)

    return container

func _on_close_pressed() -> void:
    Vars.input.focus.set_focused(self)
    close_requested.emit()

func _enter_tree() -> void:
    var childs = get_children()
    for child in childs:
        remove_child(child)
    var container = create_nodes()
    for child in childs:
        container.add_child(child)
    iter_owner(container)

func iter_owner(node: Node) -> void:
    node.owner = self
    for child in node.get_children(true):
        iter_owner(child)

func _ready() -> void:
    windows.append(self) 
    to_top()
    set_size(size)
    set_title(title)
    center()

func to_top() -> void:
    windows.erase(self)
    windows.append(self)
    for index in windows.size():
        windows[index].layer = index + 512

func is_top() -> bool:
    return windows.back() == self

func center() -> void:
    if not panel: return
    panel.anchors_preset = Control.PRESET_CENTER
    panel.position = get_viewport().get_visible_rect().size / 2 - panel.size / 2

func set_title(new_title: String) -> void:
    title = new_title
    if not title_button: return
    title_button.text = new_title

func set_size(new_size: Vector2) -> void:
    size = new_size
    if not panel: return
    panel.size = new_size + Vector2(0, 16)

func show_window() -> void:
    visible = true
    to_top()

func hide_window() -> void:
    hide()
    Vars.input.focus.remove_focused_if_is(self)

func _on_title_button_gui_input(event: InputEvent) -> void:
    var velocity = Vector2.ZERO
    if event is InputEventMouseMotion:
        if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
            velocity = event.relative
            Vars.input.focus.set_focused(self)
    if event is InputEventScreenDrag:
        velocity = event.relative
        Vars.input.focus.set_focused(self)
    if velocity != Vector2.ZERO:
        panel.position += velocity

func _handle_input(_event: InputEvent) -> void:
    pass

func _input(event: InputEvent) -> void:
    if not visible: return
    if event is InputEventMouseButton:
        var current = get_viewport().gui_get_focus_owner()
        while current:
            if current == self: break
            current = current.get_parent()
        if current == self:
            to_top()
            Vars.input.focus.set_focused(self)
    if not Vars.input.focus.is_focused(self): return
    _handle_input(event)
