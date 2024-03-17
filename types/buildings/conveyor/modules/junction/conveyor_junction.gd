class_name EntityNode_ConveyorJunction
extends EntityNode_ConveyorModule

@export var left_right_track: EntityNode_Conveyor_ConveyorTrack;
@export var down_up_track: EntityNode_Conveyor_ConveyorTrack;

func get_track(side: Sides, position: Vector2) -> EntityNode_Conveyor_ConveyorTrack.SingleTrack:
    if side == Sides.left or side == Sides.right:
        if position.y > 0: return left_right_track.right_track
        return left_right_track.left_track
    if side == Sides.up or side == Sides.down:
        if position.x > 0: return down_up_track.right_track
        return down_up_track.left_track
    return null

const SIDE_TO_DIRECTION_TO_POSITION = {
    Sides.left: {
        Directions.left: Vector2(-16, -7),
        Directions.right: Vector2(-16, 7),
        Directions.drop_far: Vector2(8, 0),
        Directions.drop_near: Vector2(-8, 0),
    },
    Sides.right: {
        Directions.drop_far: Vector2(-8, 0),
        Directions.drop_near: Vector2(8, 0),
    },
    Sides.up: {
        Directions.drop_far: Vector2(0, 8),
        Directions.drop_near: Vector2(0, -8),
    },
    Sides.down: {
        Directions.left: Vector2(-7, 16),
        Directions.right: Vector2(7, 16),
        Directions.drop_far: Vector2(0, -8),
        Directions.drop_near: Vector2(0, 8),
    },
}

func get_target_position(side: Sides, direction: Directions) -> Vector2:
    return SIDE_TO_DIRECTION_TO_POSITION[side][direction]

func _check_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> bool:
    var item: Item = args[0]
    var source_side = get_building_side(source, source_component)
    var source_direction: Directions = args[1]
    var source_position: Vector2 = args[2].rotated(rotation)
    if not SIDE_TO_DIRECTION_TO_POSITION[source_side].has(source_direction): return false
    var position = get_target_position(source_side, source_direction)
    var track = get_track(source_side, position)
    return track.test_position(position - track.base_position + source_position)

func _handle_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    var item: Item = args[0]
    var source_side = get_building_side(source, source_component)
    var source_direction: Directions = args[1]
    var source_position: Vector2 = args[2].rotated(rotation)
    if not SIDE_TO_DIRECTION_TO_POSITION[source_side].has(source_direction): return false
    var position = get_target_position(source_side, source_direction)
    var track = get_track(source_side, position)
    var item_pos = position - track.base_position + source_position
    var success = track.try_add_item(item, item_pos)
    return null if success else item

func push_reached_items() -> void:
    var right_target_component = get_component(Sides.right, "conveyor")
    if right_target_component:
        push_reached_item_for_track(right_target_component, left_right_track)
    var up_target_component = get_component(Sides.up, "conveyor")
    if up_target_component:
        push_reached_item_for_track(up_target_component, down_up_track)

func _get_tracks() -> Array[EntityNode_Conveyor_ConveyorTrack]:
    return [left_right_track, down_up_track]

func _process_update(delta: float) -> void:
    push_reached_items()

