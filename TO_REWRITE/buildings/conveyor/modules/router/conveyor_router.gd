class_name EntityNode_ConveyorRouter
extends EntityNode_ConveyorModule

enum TrackMode{
    IGNORE, INPUT, OUTPUT
}

@export var tracks: Array[EntityNode_Conveyor_ConveyorTrack] = []
var track_modes: Array[TrackMode] = [TrackMode.IGNORE, TrackMode.IGNORE, TrackMode.IGNORE, TrackMode.IGNORE]
var left_distribution_index: int = 0
var right_distribution_index: int = 0

func _get_track(side: Sides, direction: Directions, position: Vector2) -> EntityNode_Conveyor_ConveyorTrack.SingleTrack:
    var track = tracks[SIDE_TO_ROT[side]]
    return track.left_track if direction == Directions.left else track.right_track

const SIDE_TO_DIRECTION_TO_POSITION = {
    Sides.left: {
        Directions.left: Vector2(-16, -7),
        Directions.right: Vector2(-16, 7),
    },
    Sides.right: {
        Directions.left: Vector2(16, 7),
        Directions.right: Vector2(16, -7),
    },
    Sides.up: {
        Directions.left: Vector2(7, -16),
        Directions.right: Vector2(-7, -16),
    },
    Sides.down: {
        Directions.left: Vector2(-7, 16),
        Directions.right: Vector2(7, 16),
    },
}

const SIDE_TO_DIRECTION_TO_SOURCE_POSITION = {
    Sides.left: {
        Directions.left: Vector2(-8, 7),
        Directions.right: Vector2(-8, -7),
    },
    Sides.right: {
        Directions.left: Vector2(8, -7),
        Directions.right: Vector2(8, 7),
    },
    Sides.up: {
        Directions.left: Vector2(-7, -8),
        Directions.right: Vector2(7, -8),
    },
    Sides.down: {
        Directions.left: Vector2(7, 8),
        Directions.right: Vector2(-7, 8),
    },
}

const SIDE_TO_DIRECTION_TO_INPUT_TARGET_POSITION = {
    Sides.left: {
        Directions.left: Vector2(-8, -7),
        Directions.right: Vector2(-8, 7),
    },
    Sides.right: {
        Directions.left: Vector2(8, 7),
        Directions.right: Vector2(8, -7),
    },
    Sides.up: {
        Directions.left: Vector2(7, -8),
        Directions.right: Vector2(-7, -8),
    },
    Sides.down: {
        Directions.left: Vector2(-7, 8),
        Directions.right: Vector2(7, 8),
    },
}

func _get_target_position(side: Sides, direction: Directions) -> Vector2:
    return SIDE_TO_DIRECTION_TO_POSITION[side][direction]

func _is_vaild_source(source_side: Sides, source_direction: Directions) -> bool:
    return SIDE_TO_DIRECTION_TO_POSITION[source_side].has(source_direction)

func _has_side(side: Sides) -> bool:
    return track_modes[SIDE_TO_ROT[side]] == TrackMode.OUTPUT

func _handle_get_data(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    match name:
        "router": return true
    return super._handle_get_data(name, source, source_component, args)

func _check_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> bool:
    if source_component.get_data("router", entity, self) == true: return false
    return super._check_transfer(name, source, source_component, args)

func update_ports() -> void:
    for rot in tracks.size():
        var side = ROT_TO_SIDE[rot]
        var track = tracks[rot]
        var component = get_component(side, "conveyor", true)
        if component and component.check_transfer("conveyor", entity, self, [null, Directions.left]):
            track_modes[rot] = TrackMode.OUTPUT
            track.left_track_end = _get_target_position(side, Directions.right)
            track.right_track_end = _get_target_position(side, Directions.left)
            continue
        if component and component.has_side(revert_sides(side)):
            track_modes[rot] = TrackMode.INPUT
        else: track_modes[rot] = TrackMode.IGNORE
        track.left_track_end = SIDE_TO_DIRECTION_TO_INPUT_TARGET_POSITION[side][Directions.left]
        track.right_track_end = SIDE_TO_DIRECTION_TO_INPUT_TARGET_POSITION[side][Directions.right]

func distribute_single_track(track: EntityNode_Conveyor_ConveyorTrack.SingleTrack, direction: Directions) -> void:
    if not track.reached_item: return
    var index = left_distribution_index if direction == Directions.left else right_distribution_index
    if track_modes[index] == TrackMode.OUTPUT:
        var target_track = tracks[index].left_track if direction == Directions.left else tracks[index].right_track
        var target_side = ROT_TO_SIDE[index]
        var target_position = SIDE_TO_DIRECTION_TO_SOURCE_POSITION[target_side][direction] - target_track.base_position
        var success = target_track.try_add_exists_item(track.reached_item, target_position)
        track.set_reached_item(null if success else track.reached_item)
    index = (index + 1) % 4
    if direction == Directions.left: left_distribution_index = index
    else: right_distribution_index = index

func push_reached_items() -> void:
    for rot in tracks.size():
        var side = ROT_TO_SIDE[rot]
        var track = tracks[rot]
        if track_modes[rot] == TrackMode.INPUT or track_modes[rot] == TrackMode.IGNORE:
            distribute_single_track(track.left_track, Directions.left)
            distribute_single_track(track.right_track, Directions.right)
            continue
        if track_modes[rot] == TrackMode.OUTPUT:
            var component = get_component(side, "conveyor")
            if not component: continue
            push_reached_item_for_track(component, track)

func _get_tracks() -> Array[EntityNode_Conveyor_ConveyorTrack]:
    return tracks

func _ready() -> void:
    super._ready()
    await get_tree().process_frame
    update_ports()

func _process_update(delta: float) -> void:
    update_ports()
    push_reached_items()

func _save_data(stream: Stream) -> void:
    stream.store_8(left_distribution_index)
    stream.store_8(right_distribution_index)

func _load_data(stream: Stream) -> void:
    left_distribution_index = stream.get_8()
    right_distribution_index = stream.get_8()
