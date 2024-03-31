class_name BuilderAdapter
extends EntityAdapter

@export var builder_unit_positions: Array[Marker2D] = [];
@export var builder_type: BuilderAdapterUnitType;

@export var item_source: ItemAdapter;
@export var effectity_adapter: EffectityAdapter;

var units: Array[BuilderAdapterUnit] = []

func _enter_tree() -> void:
    for marker in builder_unit_positions:
        if marker.get_child_count() != 0: continue
        var unit = builder_type.create_adapter_unit(self)
        unit.init_unit()
        units.append(unit)
        marker.add_child(unit)

func get_effectity() -> float:
    return effectity_adapter.get_effectity() if effectity_adapter else 1

func update_building(controller: Controller, _adapter: ControllerAdapter) -> void:
    if controller._get_build_paused(): return
    var build_plan = controller._get_build_plan()
    for unit in units:
        unit.current_build_plan = null
    for plan in build_plan:
        build_plan_process(plan)

func _process(delta: float) -> void:
    for unit in units:
        unit.process(delta)

func build_plan_process(plan: BuildPlan) -> void:
    plan.building = false
    if not plan.check_passed:
        return
    if plan.world_id != entity_node.world.world_id: return
    var accessible = false
    for unit in units:
        if unit.check_access_range(plan.world, Tile.to_world_pos(plan.position)):
            accessible = true
            break
    if not accessible: return
    var tile = plan.world.get_tile_or_null(plan.position)
    if tile == null:
        plan.check_passed = false
        return
    if plan.breaking:
        process_break(plan, tile)
    else:
        process_build(plan, tile)

func process_build(plan: BuildPlan, tile: Tile) -> void:
    if should_place_build_shadow(plan, tile) \
            and not place_build_shadow(plan, tile):
        plan.check_passed = false
        return
    if not tile.building_shadow.entity.accept_access(main_node):
        plan.check_passed = false
        return
    for unit in units:
        if unit.current_build_plan == null:
            unit.current_build_plan = plan
            plan.building = true
            return

func process_break(plan: BuildPlan, tile: Tile) -> void:
    if tile.building_ref == 0:
        plan.build_finished = true
        return
    if tile.building and not tile.building.accept_access(main_node):
        plan.check_passed = false
        return
    if tile.building_shadow and not tile.building_shadow.entity.accept_access(main_node):
        plan.check_passed = false
        return
    for unit in units:
        if unit.current_build_plan == null:
            unit.current_build_plan = plan
            plan.building = true
            return

func should_place_build_shadow(plan: BuildPlan, tile: Tile) -> bool:
    if not tile.building_shadow: return true
    var shadow = tile.building_shadow
    if shadow.building_type != plan.building_type: return true
    if shadow.shadow.pos != plan.position: return true
    if shadow.shadow.rot != plan.rotation: return true
    # TODO team check
    return false

func place_build_shadow(plan: BuildPlan, tile: Tile) -> bool:
    if not plan.building_type: return false
    var shadow = plan.building_type.create_shadow()
    shadow.update_position({
        "building_config": plan.building_config,
        "position": plan.position,
        "rotation": plan.rotation,
        "world": plan.world,
        "layer": entity_node.layer
    })
    shadow.disable_collision = true
    plan.world.add_temp_node(shadow)
    shadow.build_progress = 0
    var result = shadow.check_build()
    shadow.queue_free()
    if not result: return false
    tile.set_building_shadow(plan.building_type, plan.rotation, plan.building_config)
    return true

func _should_save_data() -> bool:
    return true

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        for index in range(stream.get_16()):
            var mark = builder_unit_positions[index]
            if mark.get_child_count() == 0:
                var unit = builder_type.create_adapter_unit(self)
                units.append(unit)
                mark.add_child(unit)
            var unit = units[index]
            unit.load_data(stream),
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_16(units.size())
        for unit in units:
            unit.save_data(stream),
    ])
