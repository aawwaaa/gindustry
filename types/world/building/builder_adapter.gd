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
        unit._init_unit()
        units.append(unit)
        marker.add_child(unit)

func get_effectity() -> float:
    return effectity_adapter.get_effectity() if effectity_adapter else 1

func update_building(controller: Controller, _adapter: ControllerAdapter) -> void:
    var build_plan = controller._get_build_plan()
    for unit in units:
        unit.current_building_plan = null
    var removes: Array[BuildPlan] = []
    for plan in build_plan:
        build_plan_process(plan, removes)
    for remove in removes:
        build_plan.erase(remove)

func build_plan_process(plan: BuildPlan, removes: Array[BuildPlan]) -> void:
    plan.building = false
    if plan.paused: return
    if not plan.check_passed:
        return
    if plan.world != entity_node.world: return
    var accessible = false
    for unit in units:
        if unit.check_access_range(plan.world, plan.pos):
            accessible = true
            break
    if not accessible: return
    var tile = plan.world.get_tile_or_null(plan.pos)
    if tile == null:
        plan.check_passed = false
        return
    if plan.breaking:
        if tile.building_ref == 0:
            plan.build_finished = true
            return
        for unit in units:
            if unit.current_build_plan == null:
                unit.current_building_plan = plan
                plan.building = true
                return
    if should_place_build_shadow(plan, tile) \
            and not place_build_shadow(plan, tile):
        plan.check_passed = false
        return
    for unit in units:
        if unit.current_building_plan == null:
            unit.current_build_plan = plan
            plan.building = true
            return

func should_place_build_shadow(plan: BuildPlan, tile: Tile) -> bool:
    if not tile.building_shadow: return true
    var shadow = tile.building_shadow
    if shadow.building_type != plan.building_type: return true
    if Tile.to_tile_pos(shadow.position) != plan.pos: return true
    if shadow.rotation - plan.rotation > PI / 180: return true
    # TODO team check
    return false

func place_build_shadow(plan: BuildPlan, tile: Tile) -> bool:
    var shadow = plan.building_type.create_shadow()
    shadow.building_config = plan.building_config
    shadow.position = Tile.to_world_pos(plan.pos)
    shadow.rotation = plan.rotation
    plan.world.add_temp_node(shadow)
    var result = shadow._check_build()
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
            unit._load_data(stream),
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_16(units.size())
        for unit in units:
            unit._save_data(stream),
    ])
