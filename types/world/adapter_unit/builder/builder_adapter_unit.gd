class_name BuilderAdapterUnit
extends AdapterUnit

var type: BuilderAdapterUnitType:
    get: return adapter_unit_type

var current_build_plan: BuildPlan;
var overflowed_costs: float;

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
    var distance = entity.main_node.position.distance_to(target)
    var shape = %CollisionShape2D.shape
    if not (shape is CircleShape2D): return false
    return distance < shape.radius

func process(delta: float) -> void:
    update_build_target()
    overflowed_costs += delta * adapter.get_effectity() * type.build_speed
    if overflowed_costs <= 0: return
    if current_build_plan == null: 
        overflowed_costs = 0
        return
    if current_build_plan.breaking: process_break()
    else: process_build()

func update_build_target() -> void:
    if not current_build_plan:
        %CanvasGroup.visible = false
        return
    var pos = to_local(Tile.to_world_pos(current_build_plan.pos))
    %CanvasGroup.visible = true
    %Line.points[1] = pos
    %End.points[0] = pos
    %End.points[1] = pos + Vector2.ONE
    %PlaceIcon.position = pos
    %BreakIcon.position = pos
    %PlaceIcon.visible = not current_build_plan.breaking
    %BreakIcon.visible = current_build_plan.breaking

func process_build() -> void:
    var tile = current_build_plan.world.get_tile_or_null(current_build_plan.pos)
    if tile.building: current_build_plan.build_finished = true
    if not tile.building_shadow: return
    var missings = tile.building_shadow.missing_items
    var split_amounts: Array[int] = []
    split_amounts.resize(missings.size())
    split_amounts.fill(0)
    var item_index = 0
    for missing in missings:
        var used_costs = minf(missing._get_cost(), overflowed_costs)
        var amount = mini(missing.amount, missing._get_amount(used_costs))
        split_amounts[item_index] = amount
        item_index += 1
    for index in split_amounts.size():
        if split_amounts[index] <= 0: continue
        var removed = adapter.item_source._remove_item(missings[index], split_amounts[index])
        var removed_costs = removed._get_cost()
        var left = tile.building_shadow.fill_item(removed)
        var left_costs = left._get_cost()
        if not left._is_empty(): left = adapter.item_source._add_item(left)
        if not left._is_empty(): adapter.item_source._handle_overflow_item(left)
        overflowed_costs -= removed_costs - left_costs
        if overflowed_costs <= 0: break
    if tile.building_shadow == null: current_build_plan.build_finished = true
    else: current_build_plan.build_progress = tile.building_shadow.shadow.build_progress

func process_break() -> void: 
    var tile = current_build_plan.world.get_tile_or_null(current_build_plan.pos)
    if tile.building:
        var result = tile.building._handle_break(self)
        if not result: return
        tile.building.shadow._handle_break(self)
        return
    var result = tile.building_shadow.remove_item(overflowed_costs)
    for item in result["removed_items"]:
        item = adapter.item_source._add_item(item)
        if not item._is_empty(): adapter.item_source._handle_overflow_item(item)
    overflowed_costs = result["costs"]
    if tile.building_ref == 0: current_build_plan.build_finished = true
    elif tile.building_shadow:
        current_build_plan.build_progress = 1 - tile.building_shadow.shadow.build_progress

