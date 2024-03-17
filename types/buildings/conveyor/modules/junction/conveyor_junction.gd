class_name EntityNode_ConveyorJunction
extends EntityNode_ConveyorModule

@export var left_right_track: EntityNode_Conveyor_ConveyorTrack;
@export var down_up_track: EntityNode_Conveyor_ConveyorTrack;

func _get_track(side: Sides, direction: Directions, position: Vector2) -> EntityNode_Conveyor_ConveyorTrack.SingleTrack:
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

func _get_target_position(side: Sides, direction: Directions) -> Vector2:
    return SIDE_TO_DIRECTION_TO_POSITION[side][direction]

func _is_vaild_source(source_side: Sides, source_direction: Directions) -> bool:
    return SIDE_TO_DIRECTION_TO_POSITION[source_side].has(source_direction)

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

