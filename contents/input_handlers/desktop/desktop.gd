class_name DesktopInputHandler
extends InputHandler

static var keys = {}
static var signals = {
    "build_ui": {},
}

var camera: DesktopInputHandler_Camera

var item_use_position: Vector2;
var item_use: ItemUse;

var building_shadow_position: Vector2;
var building_shadow: BuildingShadow;

func _ready() -> void:
    super._ready()

    camera = DesktopInputHandler_Camera.new(self)
    add_child(camera)

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

func _load_ui(node: Control) -> void:
    merge_build_ui_signals(signals["build_ui"])
    Utils.connect_signal_by_table(GameUI.instance.build_ui, signals["build_ui"])

func _unload_ui(node: Control) -> void:
    Utils.disconnect_signal_by_table(GameUI.instance.build_ui, signals["build_ui"])

func merge_build_ui_signals(table: Dictionary) -> void:
    table.merge({
        
    })

func handle_unhandled_input_event_mouse_button(event: InputEventMouseButton) -> void:
    if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
        handle_camera_zoom(event)

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

func update_debug_message() -> void:
    var pos = (entity.main_node.position / Global.TILE_SIZE).floor()
    var label = GameUI.instance.debug
    label.text = """
Pos: {pos}, {chunk_pos}, {tile_pos}
    """.format({"pos" = pos, "chunk_pos" = (pos / Global.CHUNK_SIZE).floor(),
            "tile_pos" = Vector2i(int(pos.x) & (Global.CHUNK_SIZE - 1), int(pos.y) & (Global.CHUNK_SIZE - 1))})

func update_building_shadow() -> void:
    var ui = GameUI.instance.build_ui
    var selected = ui.selected_building_type
    if ui.build_mode != "place": selected = null
    if not selected and building_shadow:
        building_shadow.queue_free()
        building_shadow = null
        return
    if not selected: return
    if item_use:
        item_use.queue_free()
        item_use = null
    if building_shadow and ( \
                building_shadow.type != selected \
                or building_shadow.world != entity.world):
        building_shadow.queue_free()
        building_shadow = null
    if not building_shadow:
        building_shadow = selected.create_shadow()
        building_shadow.world = entity.world
        entity.world.add_temp_node(building_shadow)
    building_shadow.rotation = ui.current_rotation_rad
    building_shadow.position = Tile.to_world_pos(building_shadow_position)
    var check_result = selected._check_build()
    selected._set_check_build_result(check_result)

func update_build_plan() -> void:
    var ui = GameUI.instance.build_ui
    ui.has_build_plan = controller.build_plan.size() != 0
    for plan in controller.build_plan:
        plan.paused = ui.build_paused

func handle_build_drag(event: InputEventMouse) -> void:
    pass

func update_item_use() -> void:
    var inventory = entity.get_adapter("inventory")
    var item = inventory.get_slot(inventory.hand_slot)
    if item and not item._useable_no_await(entity, entity.world, item_use_position):
        item = null
    if building_shadow:
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

