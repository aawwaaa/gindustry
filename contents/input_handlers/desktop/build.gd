class_name DesktopInputHandler_Build
extends InputHandlerModule

var signals = {}

var building_shadow_position: Vector2;
var building_shadow: BuildingShadow;

var building_buffer_center: Vector2i;
var building_buffer: Array[BuildingShadow];

var building_drag_begin: Vector2i;
var building_drag_end: Vector2i;

var enabled: bool = true:
    set(v): enabled = v; update_building_shadow()
var activate: bool = false

func _handle_process(_delta: float) -> void:
    var ui = GameUI.instance.build_ui
    if building_buffer.is_empty() and ui.has_schematic:
        ui.has_schematic = false
    if not building_buffer.is_empty() and not ui.has_schematic:
        ui.has_schematic = true
    if controller.build_plan.is_empty() and ui.has_build_plan:
        ui.has_build_plan = false
    if not controller.build_plan.is_empty() and not ui.has_build_plan:
        ui.has_build_plan = true

func _handle_input(event: InputEvent) -> void:
    if event is InputEventMouse: handle_input_event_mouse(event)

func handle_input_event_mouse(event: InputEventMouse) -> void:
    var pos = event.position
    var trans = Game.camera_node.get_viewport_transform()
    var world_pos = trans.affine_inverse() * pos
    building_shadow_position = world_pos
    if entity: update_building_shadow()
    if entity and event is InputEventMouseButton: handle_drag(event, world_pos)

func load_ui(node: Control) -> void:
    pass

func unload_ui(node: Control) -> void:
    pass

func update_building_shadow() -> void:
    var ui = GameUI.instance.build_ui
    var selected = ui.selected_building_type
    activate = selected and ui.build_mode == "place" \
            or ui.build_mode != "place"
    if ui.build_mode != "place": selected = null
    if not enabled: selected = null
    if not selected and building_shadow:
        building_shadow.queue_free()
        building_shadow = null
        return
    if not selected: return
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

func handle_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    var ui = GameUI.instance.build_ui
    if ui.build_mode == "place": handle_place_drag(event, world_pos)
    elif ui.build_mode == "break": handle_break_drag(event, world_pos)
    elif ui.build_mode == "copy": handle_copy_drag(event, world_pos)

func handle_place_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    pass

func handle_break_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    pass

func handle_copy_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    pass

func get_drag_vector() -> Vector2i:
    var x_axis_len = absi(building_drag_end.x - building_drag_begin.x)
    var y_axis_len = absi(building_drag_end.y - building_drag_begin.y)
    if x_axis_len >= y_axis_len: return Vector2i(building_drag_end.x - building_drag_begin.x, 0)
    return Vector2i(0, building_drag_end.y - building_drag_begin.y)

func confirm_build() -> void:
    pass

