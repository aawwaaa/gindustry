class_name EntityNode_ConveyorModule
extends BuildingComponent

const Directions = EntityNode_Conveyor.Directions

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

func get_component_at(pos: Vector2i, rot: int, type: String) -> BuildingComponent:
    if pos != entity.pos: return null
    if type != get_transfer_type(): return null
    return self

func push_reached_item_for(target: BuildingComponent, track: EntityNode_Conveyor_ConveyorTrack.SingleTrack, direction: EntityNode_Conveyor.Directions) -> void: 
    if not track.reached_item: return
    var item = track.get_reached_item()
    var position = track.reached_item.position.rotated(-rotation)
    if not target.check_transfer("conveyor", entity, self, [item, direction, position]): return
    track.remove_reached_item()
    var left = target.handle_transfer("conveyor", entity, self, [item, direction, position])
    if left and not left.is_empty(): track.set_reached_item(left)

func push_reached_item_for_track(target: BuildingComponent, track: EntityNode_Conveyor_ConveyorTrack) -> void:
    push_reached_item_for(target, track.left_track, Directions.left)
    push_reached_item_for(target, track.right_track, Directions.right)

func handle_break(unit: BuilderAdapterUnit) -> bool:
    var item_adapter = unit.adapter.entity_node.get_adapter("item") as ItemAdapter
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

