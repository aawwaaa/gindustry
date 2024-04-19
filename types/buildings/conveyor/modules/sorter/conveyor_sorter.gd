class_name EntityNode_ConveyorSorter
extends EntityNode_ConveyorModule

const SIDE_TO_DIRECTION_TO_POSITION = EntityNode_ConveyorRouter.SIDE_TO_DIRECTION_TO_POSITION
const SIDE_TO_DIRECTION_TO_SOURCE_POSITION = EntityNode_ConveyorRouter.SIDE_TO_DIRECTION_TO_SOURCE_POSITION
const SIDE_TO_DIRECTION_TO_INPUT_TARGET_POSITION = EntityNode_ConveyorRouter.SIDE_TO_DIRECTION_TO_INPUT_TARGET_POSITION

@export var input_track: EntityNode_Conveyor_ConveyorTrack = null

@export var tracks: Array[EntityNode_Conveyor_ConveyorTrack] = []
const used_output_tracks = [Tile.Rot.up, Tile.Rot.down]
@export var main_output_track: EntityNode_Conveyor_ConveyorTrack = null

@export var item_select_adapter: ItemSelectAdapter = null

# TODO get_config, set_config, callbacks, building_shadow, auto set ItemSelectAdapter.content_display_group from get_sub_node("group")

var side_output_enabled: Dictionary = {}

func _get_target_position(side: Sides, direction: Directions) -> Vector2:
    return SIDE_TO_DIRECTION_TO_POSITION[side][direction]

func _is_vaild_source(source_side: Sides, source_direction: Directions) -> bool:
    return source_side == Sides.left

func _has_side(side: Sides) -> bool:
    if side == Sides.left: return false
    return side == Sides.right or side_output_enabled[SIDE_TO_ROT[side]]

func update_ports() -> void:
    for rot in used_output_tracks:
        var side = ROT_TO_SIDE[rot]
        var track = tracks[rot]
        var component = get_component(side, "conveyor")
        track.left_track_end = _get_target_position(side, Directions.right)
        track.right_track_end = _get_target_position(side, Directions.left)
        var valid = component and component.check_transfer("conveyor", entity, self, [null, Directions.left])
        side_output_enabled[rot] = valid

func distribute_single_track(track: EntityNode_Conveyor_ConveyorTrack.SingleTrack, direction: Directions) -> void:
    if not track.reached_item: return
    if item_select_adapter.has_item(track.reached_item.item):
        var target_track = main_output_track.left_track if direction == Directions.left \
                else main_output_track.right_track
        var target_position = SIDE_TO_DIRECTION_TO_SOURCE_POSITION[Sides.right][direction] - target_track.base_position
        var success = target_track.try_add_exists_item(track.reached_item, target_position)
        track.set_reached_item(null if success else track.reached_item)
        return
    for index in used_output_tracks:
        if side_output_enabled[index] == false: continue
        var target_track = tracks[index].left_track if direction == Directions.left \
                else tracks[index].right_track
        var target_side = ROT_TO_SIDE[index]
        var target_position = SIDE_TO_DIRECTION_TO_SOURCE_POSITION[target_side][direction] - target_track.base_position
        var success = target_track.try_add_exists_item(track.reached_item, target_position)
        track.set_reached_item(null if success else track.reached_item)
        if success: break

func push_reached_items() -> void:
    distribute_single_track(input_track.left_track, Directions.left)
    distribute_single_track(input_track.right_track, Directions.right)
    var target = get_component(Sides.right, "conveyor")
    if target: push_reached_item_for_track(target, main_output_track)

func _get_tracks() -> Array[EntityNode_Conveyor_ConveyorTrack]:
    return tracks

func _ready() -> void:
    super._ready()
    await get_tree().process_frame
    update_ports()

func _process_update(delta: float) -> void:
    update_ports()
    push_reached_items()
