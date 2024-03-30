class_name LayerWindow
extends CanvasLayer

signal close_requested()

const CLOSE_ICON = preload("res://assets/ui/icons/cross.tres")

static var windows: Array[LayerWindow] = []

var box: VBoxContainer
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
    box = VBoxContainer.new()

    var hbox = HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.custom_minimum_size = Vector2(0, 32)
    box.add_child(hbox)

    title_button = Button.new()
    title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(title_button)

    close_button = Button.new()
    close_button.icon = CLOSE_ICON
    close_button.custom_minimum_size = Vector2(32, 32)
    close_button.pressed.connect(_on_close_pressed)
    hbox.add_child(close_button)

    var container = Container.new()
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(container)

    return container

func _on_close_pressed() -> void:
    close_requested.emit()

func _enter_tree() -> void:
    var childs = get_children()
    for child in childs:
        remove_child(child)
    var container = create_nodes()
    for child in childs:
        container.add_child(child)

func _ready() -> void:
    windows.append(self)
    set_size(size)
    set_title(title)
    to_top()

func to_top() -> void:
    windows.erase(self)
    windows.append(self)
    for index in windows.size():
        windows[index].layer = index + 512

func set_title(new_title: String) -> void:
    title_button.text = new_title
    title = new_title

func set_size(new_size: Vector2) -> void:
    box.size = new_size + Vector2(0, 32)
    size = new_size
