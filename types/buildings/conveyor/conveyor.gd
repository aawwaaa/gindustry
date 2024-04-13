class_name EntityNode_Conveyor
extends BuildingComponent

enum Directions{
    left, right, drop_far, drop_near
}
enum DisplayDirectons{
    left = 1, up = 2, down = 4
}

const TrackItem = EntityNode_Conveyor_ConveyorTrack.TrackItem

@export var entity: Building;
@export var track: EntityNode_Conveyor_ConveyorTrack
var direction: int

func get_entity() -> Entity:
    return entity

func _ready() -> void:
    building = entity as Building
    pos = entity.pos
    super._ready()
    track.left_track.rotation_offset = -rotation
    track.right_track.rotation_offset = -rotation
    await get_tree().process_frame
    update_ports()

func _draw() -> void:
    pass

func _has_side(side: Sides) -> bool:
    return side == Sides.right

func _get_transfer_type() -> String:
    return "conveyor"

func _process_update(delta: float) -> void:
    update_ports()
    push_reached_items()

func _handle_get_data(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    var side = get_building_side(source, source_component)
    match name:
        "input": return side != Sides.right
        "output": return side == Sides.right
    return super._handle_get_data(name, source, source_component, args)

func get_adapter_at(pos: Vector2i, type: String) -> EntityAdapter:
    if pos != Vector2i.ZERO or type != "item": return null
    return entity.adapters["item"]

func get_component_at(pos: Vector2i, rot: int, type: String, ignore_side = false) -> BuildingComponent:
    if pos != entity.pos: return null
    if type != get_transfer_type(): return null
    return self

func update_ports() -> void:
    var up = get_component(Sides.up, "conveyor")
    var up_value = DisplayDirectons.up if up and up.get_data("output", entity, self) else 0
    var left = get_component(Sides.left, "conveyor")
    var left_value = DisplayDirectons.left if left and left.get_data("output", entity, self) else 0
    var down = get_component(Sides.down, "conveyor")
    var down_value = DisplayDirectons.down if down and down.get_data("output", entity, self) else 0
    var old = direction
    direction = up_value | left_value | down_value
    if old != direction: entity.shadow.display_direction = direction

func _on_building_input_operation(operation: String, args: Array = []) -> void:
    if operation == InputInteracts.ITEM_I_DROP_ITEM:
        Global.input_handler.interact_access_and_operate([self, "drop_item", args])

func _on_building_remote_operation(source: Entity, operation: String, args: Array = []) -> void:
    if source.world != entity.world: return
    if operation == "drop_item":
        var type: String = args[0]
        var pos: Vector2 = to_local(args[1])
        handle_drop_item(source, type, pos)

func handle_drop_item(source: Entity, type: String, pos: Vector2) -> void:
    if not source.has_adapter(Inventory.I_DEFAULT_NAME): return
    var inventory = source.get_adapter(Inventory.I_DEFAULT_NAME) as Inventory
    var item = inventory.split_dropped_item(type)
    var track = get_track(pos)
    var item_pos = pos - track.base_position
    if track.try_add_item(item, item_pos): item = null
    inventory.merge_overflowed_dropped_item(item)

func get_track(position: Vector2) -> EntityNode_Conveyor_ConveyorTrack.SingleTrack:
    if direction == DisplayDirectons.up:
        if position.x > 0 and position.y < 0: return track.left_track
        return track.right_track
    if direction == DisplayDirectons.down:
        if position.x > 0 and position.y > 0: return track.right_track
        return track.left_track
    if position.y > 0: return track.right_track
    return track.left_track

"""
up:  right D left
          |||
left:     VVV

left  -> ==X=>
drop  ->  X X  <- D
right -> ==X=>

          ^^^
          |||
down: left D right
"""

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
        Directions.left: Vector2(7, -16),
        Directions.right: Vector2(-7, -16),
        Directions.drop_far: Vector2(0, 8),
        Directions.drop_near: Vector2(0, -8),
    },
    Sides.down: {
        Directions.left: Vector2(-7, 16),
        Directions.right: Vector2(7, 16),
        Directions.drop_far: Vector2(0, -8),
        Directions.drop_near: Vector2(0, 8),
    }
}

func get_target_position(source_side: Sides, source_direction: Directions) -> Vector2:
    return SIDE_TO_DIRECTION_TO_POSITION[source_side][source_direction]

func _check_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> bool:
    var item: TrackItem = args[0]
    var source_side = get_building_side(source, source_component)
    var source_direction: Directions = args[1]
    if not SIDE_TO_DIRECTION_TO_POSITION[source_side].has(source_direction): return false
    if not item: return true
    var position = get_target_position(source_side, source_direction)
    var track = get_track(position)
    return track.test_position(item.position + position - track.base_position)

func _handle_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    var item: TrackItem = args[0]
    var source_side = get_building_side(source, source_component)
    var source_direction: Directions = args[1]
    if not SIDE_TO_DIRECTION_TO_POSITION[source_side].has(source_direction): return item
    if not item: return item
    var position = get_target_position(source_side, source_direction)
    var track = get_track(position)
    var item_pos = position - track.base_position
    var success = track.try_add_exists_item(item, item_pos)
    return null if success else item

func push_reached_item_for(target: BuildingComponent, track: EntityNode_Conveyor_ConveyorTrack.SingleTrack, direction: Directions) -> void: 
    if not track.reached_item: return
    var item = track.reached_item
    if not target.check_transfer("conveyor", entity, self, [item, direction]): return
    var left = target.handle_transfer("conveyor", entity, self, [item, direction])
    track.set_reached_item(left)

func push_reached_items() -> void:
    var target_component = get_component(Sides.right, "conveyor")
    if not target_component: return
    push_reached_item_for(target_component, track.left_track, Directions.left)
    push_reached_item_for(target_component, track.right_track, Directions.right)

func handle_break(unit: BuilderAdapterUnit) -> bool:
    var item_adapter = unit.adapter.entity_node.get_adapter(ItemAdapter.DEFAULT_NAME) as ItemAdapter
    if not item_adapter: return false
    for track in [track.left_track, track.right_track]:
        var removes = []
        for item in track.items:
            item.item = item_adapter.add_item(item.item)
            if not item.item or item.item.is_empty(): removes.append(item)
        for remove in removes: remove.remove()
        if track.items.size() > 0: return false
    return true

func get_speed() -> float:
    return building.building_type.speed

func _on_building_on_save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        track.save_data(stream)
    ])

func _on_building_on_load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        track.load_data(stream)
    ])

