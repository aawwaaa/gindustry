class_name DesktopInputHandler
extends InputHandler

var keys = {}

var move: DesktopInputHandler_Movement
var camera: DesktopInputHandler_Camera
var item_use: DesktopInputHandler_ItemUse
var build: DesktopInputHandler_Build

func _ready() -> void:
    super._ready()

    move = DesktopInputHandler_Movement.new(self)
    add_child(move)
    camera = DesktopInputHandler_Camera.new(self)
    add_child(camera)
    item_use = DesktopInputHandler_ItemUse.new(self)
    add_child(item_use)
    build = DesktopInputHandler_Build.new(self)
    add_child(build)

    keys.merge({
        "open_pause_menu": GameUI.instance.pause_menu.toggle_pause_menu.bind(),
        "open_inventory": GameUI.instance.player_inventory.toggle_inventory.bind(),
    })

func _handle_unhandled_input(event: InputEvent) -> void:
    pass

func _handle_input(event: InputEvent) -> void:
    if event is InputEventMouse: handle_input_event_mouse(event)
    if event is InputEventKey: handle_input_event_key(event)
    item_use.handle_input(event)
    build.handle_input(event)
    
func _handle_process(_delta: float) -> void:
    if entity: update_debug_message()
    if build.activate and item_use.enabled: item_use.enabled = false
    if not build.activate and not item_use.enabled: item_use.enabled = true

func _load_ui(node: Control) -> void:
    build.load_ui(node)

func _unload_ui(node: Control) -> void:
    build.unload_ui(node)

func handle_input_event_mouse(event: InputEventMouse) -> void:
    var pos = event.position
    var trans = Game.camera_node.get_viewport_transform()
    var world_pos = trans.affine_inverse() * pos

func handle_input_event_key(event: InputEventKey) -> void:
    for key in keys:
        if Input.is_action_just_pressed(key):
            keys[key].call()

func update_debug_message() -> void:
    var pos = (entity.main_node.position / Global.TILE_SIZE).floor()
    var label = GameUI.instance.debug
    label.text = """
Pos: {pos}, {chunk_pos}, {tile_pos}
    """.format({"pos" = pos, "chunk_pos" = (pos / Global.CHUNK_SIZE).floor(),
            "tile_pos" = Vector2i(int(pos.x) & (Global.CHUNK_SIZE - 1), int(pos.y) & (Global.CHUNK_SIZE - 1))})


