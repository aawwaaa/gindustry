class_name DesktopInputHandler_Build
extends InputHandlerModule

var signals = {}

var building_shadow_position: Vector2;
var building_shadow: BuildingShadow;

var building_buffer: Array[BuildingShadow] = [];
var building_drag_buffer: Array[BuildingShadow] = [];

var break_buffer: Array[int] = [];
var break_drag_buffer: Array[int] = [];

var dragging: bool = false
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

func handle_input(event: InputEvent) -> void:
    if event is InputEventMouse: handle_input_event_mouse(event)

func handle_input_event_mouse(event: InputEventMouse) -> void:
    var pos = event.position
    var trans = Game.camera_node.get_viewport_transform()
    var world_pos = trans.affine_inverse() * pos
    building_shadow_position = Tile.to_tile_pos(world_pos)
    if entity: update_building_shadow()
    if entity: handle_drag(event, world_pos)

func load_ui(node: Control) -> void:
    signals.merge({
        "confirm_build": confirm_build.bind(),
        "build_paused_changed": _on_build_paused_changed.bind(),
        "build_plan_operate": _on_build_plan_operate.bind()
    })
    Utils.connect_signal_by_table(GameUI.instance.build_ui, signals)

func unload_ui(node: Control) -> void:
    Utils.disconnect_signal_by_table(GameUI.instance.build_ui, signals)

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
                building_shadow.building_type != selected \
                or building_shadow.world != entity.world):
        building_shadow.queue_free()
        building_shadow = null
    if not building_shadow:
        building_shadow = selected.create_shadow()
        building_shadow.world = entity.world
        building_shadow.disable_collision = true
        entity.world.add_temp_node(building_shadow)
        building_shadow.layer = entity.layer
        building_shadow.build_progress = 1
    building_shadow.rotation = ui.current_rotation_rad
    building_shadow.position = Tile.to_world_pos(building_shadow_position)
    var check_result = building_shadow._check_build()
    building_shadow._set_check_build_result(check_result)

func update_build_plan() -> void:
    var ui = GameUI.instance.build_ui
    ui.has_build_plan = controller.build_plan.size() != 0
    for plan in controller.build_plan:
        plan.paused = ui.build_paused

func handle_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    var ui = GameUI.instance.build_ui
    if ui.build_mode == "place" and ui.selected_building_type: handle_place_drag(event, world_pos)
    if ui.build_mode == "break": handle_break_drag(event, world_pos)
    if ui.build_mode == "copy": handle_copy_drag(event, world_pos)

func handle_place_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    var ui = GameUI.instance.build_ui
    var building_type = ui.selected_building_type
    if event is InputEventMouseButton and event.is_pressed():
        building_drag_begin = Tile.to_tile_pos(world_pos)
        dragging = true
    if not dragging: return
    building_drag_end = Tile.to_tile_pos(world_pos)
    var drag_vector = get_drag_vector()
    var step = Vector2i(Vector2(drag_vector).normalized())
    var current_pos = Vector2i.ZERO
    for shadow in building_drag_buffer:
        shadow.queue_free()
    building_drag_buffer.clear()
    var current_shadow: BuildingShadow = null
    while current_pos.length_squared() < drag_vector.length_squared():
        if not current_shadow:
            current_shadow = building_type.create_shadow()
            current_shadow.world = entity.world
            current_shadow.rotation = ui.current_rotation_rad
            current_shadow.layer = entity.layer
            current_shadow.disable_collision = true
            entity.world.add_temp_node(current_shadow) 
            current_shadow.build_progress = 1
        var tile_pos = building_drag_begin + current_pos
        current_shadow.position = Tile.to_world_pos(tile_pos)
        if current_shadow._check_build():
            building_drag_buffer.append(current_shadow)
            current_shadow = null
        current_pos += step
    if current_shadow: current_shadow.queue_free()
    if event is InputEventMouseButton and not event.is_pressed():
        dragging = false
        confirm_build_drag()

func handle_break_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    if event is InputEventMouseButton and event.is_pressed():
        building_drag_begin = Tile.to_tile_pos(world_pos)
        dragging = true
    if not dragging: return
    building_drag_end = Tile.to_tile_pos(world_pos)
    break_drag_buffer.clear()
    var begin = Vector2i(mini(building_drag_begin.x, building_drag_end.x), \
            mini(building_drag_begin.y, building_drag_end.y))
    var end = Vector2i(maxi(building_drag_begin.x, building_drag_end.x), \
            maxi(building_drag_begin.y, building_drag_end.y))
    var current_pos = begin
    while current_pos.y < end.y:
        while current_pos.x < end.x:
            var tile = entity.world.get_tile_or_null(current_pos)
            if tile.building_ref != 0 and not break_drag_buffer.has(tile.building_ref):
                break_drag_buffer.append(tile.building_ref)
        current_pos.x = begin.x
        current_pos.y += 1
    if event is InputEventMouseButton and not event.is_pressed():
        dragging = false
        break_buffer.append_array(break_drag_buffer)
        break_drag_buffer.clear()
        buffer_updated()

func handle_copy_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    pass

func confirm_build_drag() -> void:
    for node in building_drag_buffer:
        node.get_parent().remove_child(node)
    var current = building_drag_buffer.pop_front()
    current.world.add_child(current)
    if not current: return
    while building_drag_buffer.size() > 0:
        var next = building_drag_buffer.pop_front()
        next.world.add_child(next)
        await get_tree().physics_frame
        if not next._check_build():
            next.queue_free()
            continue
        building_buffer.append(current)
        current = next
    buffer_updated()

func get_drag_vector() -> Vector2i:
    var x_axis_len = absi(building_drag_end.x - building_drag_begin.x)
    var y_axis_len = absi(building_drag_end.y - building_drag_begin.y)
    if x_axis_len >= y_axis_len: return Vector2i(building_drag_end.x - building_drag_begin.x, 0)
    return Vector2i(0, building_drag_end.y - building_drag_begin.y)

func buffer_updated(no_confirm = false) -> void:
    if not no_confirm: confirm_build()

func confirm_build() -> void:
    var ui = GameUI.instance.build_ui
    var exists_build_plan: Dictionary = {}
    for plan in controller.build_plan:
        if plan.world != entity.world: continue
        exists_build_plan[plan.pos] = plan
    for shadow in building_buffer:
        if not shadow._check_build(): continue
        var tile_pos = Tile.to_tile_pos(shadow.position)
        var plan = BuildPlan.new()
        plan.building_type = shadow.building_type
        plan.pos = tile_pos
        plan.rotation = shadow.rotation
        plan.world = entity.world
        plan.building_config = shadow.building_config
        plan.paused = ui.build_paused
        controller.build_plan.append(plan)
    for shadow in building_buffer:
        shadow.queue_free()
    building_buffer.clear()
    for entity_ref in break_buffer:
        var entity = Entity.get_entity_by_ref_or_null(entity_ref)
        if not entity: continue
        var tile_pos = Tile.to_tile_pos(entity.position)
        if exists_build_plan.has(tile_pos):
            controller.build_plan.erase(exists_build_plan[tile_pos])
        var plan = BuildPlan.new()
        plan.pos = tile_pos
        plan.breaking = true
        plan.paused = ui.build_paused
        controller.build_plan.append(plan)
    break_buffer.clear()

func _on_build_paused_changed(paused: bool) -> void:
    for plan in controller.build_plan:
        plan.paused = paused

func _on_build_plan_operate(operation: String) -> void:
    # clear, cancel, vertical-flip, horizonal-flip, rotate-left, rotate-right, save
    if operation == "clear":
        building_buffer.clear()
        break_buffer.clear()
    if operation == "cancel":
        controller.build_plan.clear()
    # todo scematic operation

