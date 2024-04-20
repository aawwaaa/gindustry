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

var side_output_enabled: Array = [false, false, false, false]

func _get_target_position(side: Sides, direction: Directions) -> Vector2:
    return SIDE_TO_DIRECTION_TO_POSITION[side][direction]

func _is_vaild_source(source_side: Sides, source_direction: Directions) -> bool:
    return source_side == Sides.left

func _has_side(side: Sides) -> bool:
    if side == Sides.left: return false
    return side == Sides.right or side_output_enabled[SIDE_TO_ROT[side]]

func _get_track(side: Sides, direction: Directions, position: Vector2) -> EntityNode_Conveyor_ConveyorTrack.SingleTrack:
    if side != Sides.left: return null
    return input_track.left_track if direction == Directions.left else input_track.right_track

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
    target = get_component(Sides.up, "conveyor")
    if target: push_reached_item_for_track(target, tracks[Tile.Rot.down])
    target = get_component(Sides.down, "conveyor")
    if target: push_reached_item_for_track(target, tracks[Tile.Rot.up])

func _get_tracks() -> Array[EntityNode_Conveyor_ConveyorTrack]:
    return tracks

func _ready() -> void:
    super._ready()
    item_select_adapter.content_display_group = building.shadow.get_sub_node("group")
    item_select_adapter.sprite2d = building.shadow.display_sprite
    item_select_adapter.sprite2d_blacklist_texture = building.building_type.texture_blacklist_texture
    item_select_adapter.sprite2d_whitelist_texture = building.building_type.texture_texture
    item_select_adapter.set_blacklist(item_select_adapter.blacklist)
    await get_tree().process_frame
    update_ports()

func _process_update(delta: float) -> void:
    update_ports()
    push_reached_items()

func get_config() -> Variant:
    return AdapterConfig.generate_config({
        ItemSelectAdapter.CONFIG_KEY: item_select_adapter
    })

func set_config(config: Variant) -> void:
    AdapterConfig.apply_config(config, {
        ItemSelectAdapter.CONFIG_KEY: item_select_adapter
    })

func _on_building_input_operation(operation: String, args: Array) -> void:
    if operation == InputInteracts.INTERACT_I_DIRECT_INTERACT:
        Global.input_handler.interact_access_target_ui(self)

