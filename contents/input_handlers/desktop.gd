class_name DesktopInputHandler
extends InputHandler

static var keys = {}

var camera_position: Vector2;
var camera_rotation: float;
var camera_zoom: float = 1;

var item_use_position: Vector2;
var item_use: ItemUse;

func _ready() -> void:
    super._ready()
    keys.merge({
        "open_pause_menu": GameUI.instance.pause_menu.toggle_pause_menu.bind(),
        "open_inventory": GameUI.instance.player_inventory.toggle_inventory.bind(),
    })

func _handle_unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton: handle_unhandled_input_event_mouse_button(event)

func _handle_input(event: InputEvent) -> void:
    if event is InputEventMouse: handle_input_event_mouse(event)
    if event is InputEventKey: handle_input_event_key(event)
    
func _handle_process(_delta: float) -> void:
    if entity: update_debug_message()
    if controller: update_move()
    if target: update_camera()

func handle_unhandled_input_event_mouse_button(event: InputEventMouseButton) -> void:
    if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
        handle_camera_zoom(event)

func handle_camera_zoom(event: InputEventMouseButton) -> void:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
        camera_zoom *= 1.1
    if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        camera_zoom /= 1.1

func handle_input_event_key(event: InputEventKey) -> void:
    for key in keys:
        if Input.is_action_just_pressed(key):
            keys[key].call()

func handle_input_event_mouse(event: InputEventMouse) -> void:
    var pos = event.position
    var trans = Game.camera_node.get_viewport_transform()
    var world_pos = trans.affine_inverse() * pos
    if entity: handle_item_use_mouse(world_pos)

func handle_item_use_mouse(world_pos: Vector2) -> void:
    item_use_position = world_pos
    if Input.is_action_just_pressed("item_use_confirm"):
        confirm_item_use()

func update_move() -> void:
    controller.move_velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down");
    
func update_camera() -> void:
    camera_position = controller.get_target_attribute("position")
    camera_rotation = controller.get_target_attribute("rotation")
    if camera_position != null:
        Game.camera_base_node.position = camera_position;
        Game.camera_base_node.rotation = camera_rotation;
    Game.camera_node.zoom = Game.camera_node.zoom.lerp(Vector2(camera_zoom, camera_zoom), 0.15);

func update_debug_message() -> void:
    var pos = (entity.main_node.position / Global.TILE_SIZE).floor()
    var label = GameUI.instance.debug
    label.text = """
Pos: {pos}, {chunk_pos}, {tile_pos}
    """.format({"pos" = pos, "chunk_pos" = (pos / Global.CHUNK_SIZE).floor(),
            "tile_pos" = Vector2i(int(pos.x) & (Global.CHUNK_SIZE - 1), int(pos.y) & (Global.CHUNK_SIZE - 1))})

func update_item_use() -> void:
    var inventory = entity.get_adapter("inventory")
    var item = inventory.get_slot(inventory.hand_slot)
    if item and not item._useable_no_await(entity, entity.world, item_use_position):
        item = null
    if not item and item_use:
        item_use.queue_free()
        item_use = null
        return
    if not item: return
    if item_use and item_use.item != item:
        item_use.queue_free()
        item_use = null
    if not item_use:
        item_use = item._create_use(entity, entity.world)
        item_use.inventory = inventory
        item_use.slot = inventory.hand_slot
    item_use._set_position(item_use_position)

func confirm_item_use() -> void:
    if not item_use:
        return
    controller.operate_target("inventory", ["use_hand", entity.world, item_use_position])
    item_use.queue_free()
    item_use = null

