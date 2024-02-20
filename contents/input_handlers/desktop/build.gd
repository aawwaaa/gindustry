class_name DesktopInputHandler_Build
extends InputHandlerModule

const BREAK_FLAG_TEXTURE = preload("res://assets/break_flag.png")
var break_drag_range: Line2D = Line2D.new()

var signals = {}

var building_shadow_position: Vector2;
var building_shadow: BuildingShadow;

var building_buffer: Array[BuildingShadow] = [];
var building_drag_buffer: Array[BuildingShadow] = [];

var break_buffer: Dictionary = {};
var break_drag_buffer: Dictionary = {};

var dragging: bool = false;
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
    update_build_plan()

func handle_input(event: InputEvent) -> void:
    if event is InputEventMouse: handle_input_event_mouse(event)

func handle_unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouse: handle_input_event_mouse(event, true)

func handle_input_event_mouse(event: InputEventMouse, unhandled: bool = false) -> void:
    var pos = event.position
    var trans = Game.camera_node.get_viewport_transform()
    var world_pos = trans.affine_inverse() * pos
    building_shadow_position = Tile.to_tile_pos(world_pos)
    if entity: update_building_shadow()
    if entity and unhandled: handle_drag(event, world_pos)

func load_ui(node: Control) -> void:
    signals.merge({
        "confirm_build": confirm_build.bind(),
        "build_plan_operate": _on_build_plan_operate.bind()
    })
    Utils.connect_signal_by_table(GameUI.instance.build_ui, signals)
    break_drag_range.default_color = Color(1, 0.2, 0.05, 1)
    break_drag_range.width = Global.TILE_SIZE / 8
    break_drag_range.closed = true

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
                not is_instance_valid(building_shadow)
                or building_shadow.building_type != selected \
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
    building_shadow.rot = ui.current_rotation_rad
    building_shadow.position = Tile.to_world_pos(building_shadow_position)
    building_shadow.pos = building_shadow_position
    var check_result = building_shadow._check_build()
    building_shadow._set_check_build_result(check_result)

func update_build_plan() -> void:
    var ui = GameUI.instance.build_ui
    var removes: Array[BuildPlan] = []
    for plan in controller.build_plan:
        plan.paused = ui.build_paused
        if not plan.check_passed: removes.append(plan)
        if plan.build_finished: removes.append(plan)
        if plan.building and plan.preview_name != "":
            plan.world.get_temp_node(plan.preview_name).queue_free()
            plan.preview_name = ""

    for plan in removes:
        if not controller.build_plan.has(plan): continue
        if plan.preview_name != "":
            plan.world.get_temp_node(plan.preview_name).queue_free()
        controller.build_plan.erase(plan)

func handle_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    var ui = GameUI.instance.build_ui
    if ui.build_mode == "place" and ui.selected_building_type: handle_place_drag(event, world_pos)
    if ui.build_mode == "break": handle_break_drag(event, world_pos)
    if ui.build_mode == "copy": handle_copy_drag(event, world_pos)

func handle_place_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    var ui = GameUI.instance.build_ui
    var building_type = ui.selected_building_type
    if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
        return
    if event is InputEventMouseButton and event.is_pressed():
        building_drag_begin = Tile.to_tile_pos(world_pos)
        dragging = true
    if not dragging: return
    building_drag_end = Tile.to_tile_pos(world_pos)
    var drag_vector = get_drag_vector()
    var step = Vector2i(Vector2(drag_vector).normalized()) if drag_vector != Vector2i.ZERO else Vector2i.RIGHT
    var current_pos = Vector2i.ZERO
    for shadow in building_drag_buffer:
        shadow.queue_free()
    building_drag_buffer.clear()
    var current_shadow: BuildingShadow = null
    while current_pos.length_squared() <= drag_vector.length_squared():
        if not current_shadow:
            current_shadow = building_type.create_shadow()
            current_shadow.world = entity.world
            current_shadow.rotation = ui.current_rotation_rad
            current_shadow.layer = entity.layer
            current_shadow.disable_collision = true
            entity.world.add_temp_node(current_shadow) 
            current_shadow.rot = ui.current_rotation_rad
            current_shadow.build_progress = 1
        var tile_pos = building_drag_begin + current_pos
        current_shadow.pos = tile_pos
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
    if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
        return
    if event is InputEventMouseButton and event.is_pressed():
        building_drag_begin = Tile.to_tile_pos(world_pos)
        dragging = true
        entity.world.add_temp_node(break_drag_range)
    if not dragging: return
    building_drag_end = Tile.to_tile_pos(world_pos)
    for flag in break_drag_buffer.values():
        flag.queue_free()
    break_drag_buffer.clear()
    var begin = Vector2i(mini(building_drag_begin.x, building_drag_end.x), \
            mini(building_drag_begin.y, building_drag_end.y))
    var end = Vector2i(maxi(building_drag_begin.x, building_drag_end.x), \
            maxi(building_drag_begin.y, building_drag_end.y))
    break_drag_range.clear_points()
    break_drag_range.add_point(Tile.to_world_pos(begin, Vector2.ZERO))
    break_drag_range.add_point(Tile.to_world_pos(Vector2( \
        begin.x, end.y), Vector2.DOWN * Global.TILE_SIZE))
    break_drag_range.add_point(Tile.to_world_pos(end, Global.TILE_SIZE_VECTOR))
    break_drag_range.add_point(Tile.to_world_pos(Vector2( \
        end.x, begin.y), Vector2.RIGHT * Global.TILE_SIZE))
    var current_pos = begin
    while current_pos.y <= end.y:
        while current_pos.x <= end.x:
            var tile = entity.world.get_tile_or_null(current_pos)
            if tile.building_ref != 0 and not break_drag_buffer.has(tile.building_ref):
                var flag = Sprite2D.new()
                flag.texture = BREAK_FLAG_TEXTURE
                flag.position = Tile.to_world_pos(current_pos)
                entity.world.add_temp_node(flag)
                break_drag_buffer[tile.building_ref] = flag
            current_pos.x += 1
        current_pos.x = begin.x
        current_pos.y += 1
    if event is InputEventMouseButton and not event.is_pressed():
        dragging = false
        entity.world.remove_temp_node(break_drag_range)
        confirm_break_drag()
        
func handle_copy_drag(event: InputEventMouse, world_pos: Vector2) -> void:
    if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
        return

func confirm_build_drag() -> void:
    for node in building_drag_buffer:
        entity.world.remove_temp_node(node)
    var buffer = building_drag_buffer.duplicate()
    var current = buffer.pop_front()
    if not current: return
    current.place()
    current.world.add_temp_node(current)
    building_buffer.append(current)
    while buffer.size() > 0:
        var next = buffer.pop_front()
        next.world.add_temp_node(next)
        if not next._check_build(true):
            next.queue_free()
            continue
        building_buffer.append(next)
        current = next
        next.place()
    for node in building_drag_buffer:
        node.destroy()
    building_drag_buffer.clear()
    buffer_updated()

func confirm_break_drag() -> void:
    for id in break_drag_buffer:
        if break_buffer.has(id):
            break_buffer[id].queue_free()
            continue
        break_buffer[id] = break_drag_buffer[id]
    break_drag_buffer.clear()
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
        plan.preview_name = shadow.name
        controller.build_plan.append(plan)
    building_buffer.clear()
    for entity_ref in break_buffer:
        var entity = Entity.get_entity_by_ref_or_null(entity_ref)
        if not entity:
            break_buffer[entity_ref].queue_free()
            continue
        var main_node = entity.main_node
        if exists_build_plan.has(entity.tile_pos):
            exists_build_plan[entity.tile_pos].check_passed = false
        var plan = BuildPlan.new()
        plan.world = entity.world
        plan.pos = entity.tile_pos
        plan.breaking = true
        plan.preview_name = break_buffer[entity_ref].name
        plan.paused = ui.build_paused
        controller.build_plan.append(plan)
    break_buffer.clear()

func _on_build_plan_operate(operation: String) -> void:
    # clear, cancel, vertical-flip, horizonal-flip, rotate-left, rotate-right, save
    if operation == "clear":
        building_buffer.clear()
        break_buffer.clear()
    if operation == "cancel":
        for plan in controller.build_plan:
            plan.check_passed = false
    # todo scematic operation

func _on_building_shadow_container_input(container: BuildingShadowContainer, event: InputEvent) -> void:
    var ui = GameUI.instance.build_ui
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
        var plan = BuildPlan.new()
        plan.building_type = container.building_type
        plan.pos = container.entity.tile_pos
        plan.rotation = container.rotation
        plan.world = container.entity.world
        plan.building_config = container.building_config
        plan.paused = ui.build_paused
        controller.build_plan.push_front(plan)
