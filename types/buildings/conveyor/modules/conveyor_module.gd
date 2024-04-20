class_name EntityNode_ConveyorModule
extends BuildingComponent

const Directions = EntityNode_Conveyor.Directions
const TrackItem = EntityNode_Conveyor_ConveyorTrack.TrackItem

@export var entity: Building;
var direction: int

func get_entity() -> Entity:
    return entity

func _ready() -> void:
    building = entity as Building
    pos = entity.pos
    super._ready()
    for track in get_tracks():
        track.left_track.rotation_offset = -rotation
        track.right_track.rotation_offset = -rotation

func _draw() -> void:
    pass

func _get_transfer_type() -> String:
    return "conveyor"

func _handle_get_data(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    var side = get_building_side(source, source_component)
    match name:
        "input": return not has_side(side)
        "output": return has_side(side)
    return super._handle_get_data(name, source, source_component, args)

func get_adapter_at(pos: Vector2i, type: String) -> EntityAdapter:
    if pos != Vector2i.ZERO or type != "item": return null
    return entity.adapters["item"]

func get_component_at(pos: Vector2i, rot: int, type: String, ignore_side = false) -> BuildingComponent:
    if pos != entity.pos: return null
    if type != get_transfer_type(): return null
    return self

func _get_target_position(source_side: Sides, source_direction: Directions) -> Vector2:
    return Vector2.ZERO

func _get_track(source_side: Sides, source_direction: Directions, position: Vector2) -> EntityNode_Conveyor_ConveyorTrack.SingleTrack:
    return null

func _is_vaild_source(source_side: Sides, source_direction: Directions) -> bool:
    return false

func _check_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> bool:
    var item: TrackItem = args[0]
    var source_side = get_building_side(source, source_component)
    var source_direction: Directions = args[1]
    if not _is_vaild_source(source_side, source_direction): return false
    if not item: return true
    var position = _get_target_position(source_side, source_direction)
    var track = _get_track(source_side, source_direction, position)
    return track.test_position(item.position + position - track.base_position)

func _handle_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    var item: TrackItem = args[0]
    var source_side = get_building_side(source, source_component)
    var source_direction: Directions = args[1]
    if not _is_vaild_source(source_side, source_direction): return item
    if not item: return item
    var position = _get_target_position(source_side, source_direction)
    var track = _get_track(source_side, source_direction, position)
    var item_pos = position - track.base_position
    var success = track.try_add_exists_item(item, item_pos)
    return null if success else item

func push_reached_item_for(target: BuildingComponent, track: EntityNode_Conveyor_ConveyorTrack.SingleTrack, direction: EntityNode_Conveyor.Directions) -> bool: 
    if not track.reached_item: return false
    var item = track.reached_item
    if not target.check_transfer("conveyor", entity, self, [item, direction]): return false
    var left = target.handle_transfer("conveyor", entity, self, [item, direction])
    track.set_reached_item(left)
    return true

func push_reached_item_for_track(target: BuildingComponent, track: EntityNode_Conveyor_ConveyorTrack) -> void:
    push_reached_item_for(target, track.left_track, Directions.left)
    push_reached_item_for(target, track.right_track, Directions.right)

func handle_break(unit: BuilderAdapterUnit) -> bool:
    var item_adapter = unit.adapter.entity_node.get_adapter(ItemAdapter.DEFAULT_NAME) as ItemAdapter
    if not item_adapter: return false
    for track in get_tracks().map(func(track): return [track.left_track, track.right_track]):
        for single_track in track:
            var removes = []
            for item in single_track.items:
                item.item = item_adapter.add_item(item.item)
                if not item.item or item.item.is_empty(): removes.append(item)
            for remove in removes: remove.remove()
            if single_track.items.size() > 0: return false
    return true

func _get_tracks() -> Array[EntityNode_Conveyor_ConveyorTrack]:
    return []

func get_tracks() -> Array[EntityNode_Conveyor_ConveyorTrack]:
    return _get_tracks()

func _save_data(stream: Stream) -> void:
    pass

func _load_data(stream: Stream) -> void:
    pass

func get_speed() -> float:
    return entity.building_type.conveyor_type.speed

func _on_building_on_save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        _save_data(stream)
        for track in get_tracks():
            track.save_data(stream)
    ])

func _on_building_on_load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        _load_data(stream)
        for track in get_tracks():
            track.load_data(stream)
    ])

