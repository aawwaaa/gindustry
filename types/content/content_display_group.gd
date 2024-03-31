class_name ContentDisplayGroup
extends Node2D

const AMOUNT_TO_POSITION_AND_SCALE = {
    0: [],
    1: [
        {"position": Vector2(0, 0), "scale": Vector2(1, 1)}
    ],
    2: [
        {"position": Vector2(-8, 0), "scale": Vector2(0.5, 0.5)},
        {"position": Vector2(8, 0), "scale": Vector2(0.5, 0.5)}
    ],
    3: [
        {"position": Vector2(-8, -8), "scale": Vector2(0.5, 0.5)},
        {"position": Vector2(8, -8), "scale": Vector2(0.5, 0.5)},
        {"position": Vector2(-8, 8), "scale": Vector2(0.5, 0.5)}
    ],
    4: [
        {"position": Vector2(-8, -8), "scale": Vector2(0.5, 0.5)},
        {"position": Vector2(8, -8), "scale": Vector2(0.5, 0.5)},
        {"position": Vector2(-8, 8), "scale": Vector2(0.5, 0.5)},
        {"position": Vector2(8, 8), "scale": Vector2(0.5, 0.5)}
    ]
}

const AMOUNT_TO_PANEL_SIZE = {
    0: Vector2(0, 0),
    1: Vector2(16, 16),
    2: Vector2(32, 16),
    3: Vector2(32, 32),
    4: Vector2(32, 32)
}

var panel_node: Panel
var contents: Array = []
var content_getter: Callable;

func update() -> void:
    # if >4 pick first 4
    # free existed nodes
    for child in get_children():
        if child == panel_node: continue
        child.queue_free()
    # create new nodes
    var amount = min(4, contents.size())
    for i in range(amount):
        var content = contents[i]
        var node = Sprite2D.new()
        node.texture = content.get_icon() if not content_getter else content_getter.call(content)
        var props = AMOUNT_TO_POSITION_AND_SCALE[amount][i]
        node.position = props.position
        node.scale = props.scale
        node.z_index += 1
        add_child(node)
    update_panel()

func update_panel() -> void:
    if not panel_node:
        panel_node = Panel.new()
        add_child(panel_node)
    panel_node.size = AMOUNT_TO_PANEL_SIZE[min(4, contents.size())]

