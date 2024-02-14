class_name BuilderAdapterUnit
extends AdapterUnit

var type: BuilderAdapterUnitType:
    get: return adapter_unit_type

var current_build_plan: BuildPlan;
var overflowed_times: float;

func _ready() -> void:
    entity.layer_changed.connect(_on_layer_changed)
    _on_layer_changed(entity.layer, 0)
    %CollisionShape2D.shape = type.build_range

func _on_layer_changed(layer: int, from: int) -> void:
    var mask = entity.get_collision_mask(type.build_range_layer_begin, type.build_range_layer_end)
    $Area2D.collision_mask = mask
    $Area2D.collision_layer = mask

func check_access_range(world: World, target: Vector2) -> bool:
    if world != self.world: return false
    var distance = entity.position.distance_to(target)
    var shape = %CollisionShape2D.shape
    if not (shape is CircleShape2D): return false
    return distance < shape.radius

func _process(delta: float) -> void:
    overflowed_times += delta * adapter.get_effectity()
    var build_costs = floori(overflowed_times * type.build_speed)
    overflowed_times -= build_costs / type.build_speed
    if build_costs <= 0: return
    if current_build_plan == null: return
    if current_build_plan.breaking: process_break(build_costs)
    else: process_build(build_costs)

func process_build(costs: int) -> void:
    var tile = current_build_plan.world.get_tile_or_null(current_build_plan.pos)
    var missings = tile.building_shadow.missing_items
    var split_amounts: Array[int] = []
    split_amounts.resize(missings.size())
    split_amounts.fill(0)
    var item_index = 0
    for missing in missings:
        var used_costs = minf(missing._get_cost(), costs)
        var amount = mini(missing.amount, missing._get_amount(used_costs))
        split_amounts[item_index] = amount
        costs -= used_costs
        item_index += 1
        if costs <= 0: break
    for index in split_amounts.size():
        if split_amounts[index] <= 0: continue
        var removed = adapter.item_source._remove_item(missings[index], split_amounts[index])
        var left = tile.building_shadow.fill_item(removed)
        if not left._is_empty(): left = adapter.item_source._add_item(left)
        if not left._is_empty(): adapter.item_source._handle_overflow_item(left)

func process_break(costs: int) -> void: 
    var tile = current_build_plan.world.get_tile_or_null(current_build_plan.pos)
    var items = tile.building_shadow.remove_item(costs)
    for item in items:
        item = adapter.item_source._add_item(item)
        if not item._is_empty(): adapter.item_source._handle_overflow_item(item)

