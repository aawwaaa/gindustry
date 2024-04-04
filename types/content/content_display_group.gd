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
    1: Vector2(32, 32),
    2: Vector2(32, 16),
    3: Vector2(32, 32),
    4: Vector2(32, 32)
}

var panel_node: Panel
var contents: Array[Content] = []
var datas: Array = []
var content_getter: Callable = do_nothing;

func _ready() -> void:
    scale *= 0.5
    visibility_layer = Global.ALT_DISPLAY_LAYER

static func do_nothing(v: Variant) -> Variant:
    return v

func update() -> void:
    # if >4 pick first 4
    # free existed nodes
    for child in get_children():
        if child == panel_node: continue
        child.queue_free()
    # filte
    contents.resize(0)
    for data in datas:
        var content = content_getter.call(data)
        if content: contents.append(content)
    # create new nodes
    var amount = min(4, contents.size())
    for i in range(amount):
        var content = contents[i]
        var node = Sprite2D.new()
        node.texture = content.get_icon()
        var props = AMOUNT_TO_POSITION_AND_SCALE[amount][i]
        node.position = props.position
        node.scale = props.scale
        node.z_index += 1
        add_child(node)
    update_panel()

func update_panel() -> void:
    if not panel_node:
        panel_node = Panel.new()
        panel_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(panel_node)
    panel_node.size = AMOUNT_TO_PANEL_SIZE[min(4, contents.size())]
    panel_node.position = -panel_node.size / 2

