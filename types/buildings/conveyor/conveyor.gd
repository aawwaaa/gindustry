class_name EntityNode_Conveyor
extends BuildingComponent

enum Directions{
    left, right, center
}
enum DisplayDirectons{
    left = 1, up = 2, down = 4
}

@export var entity: Building;
@export var track: EntityNode_Conveyor_ConveyorTrack
var direction: int

func get_entity() -> Entity:
    return entity

func _ready() -> void:
    building = entity as Building
    pos = entity.pos
    super._ready()

func _draw() -> void:
    pass

func _has_side(side: Sides) -> bool:
    return side == Sides.right

func _get_transfer_type() -> String:
    return "conveyor"

func _process_update(delta: float) -> void:
    update_ports()

func _handle_get_data(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    var side = get_building_side(source, source_component)
    match name:
        "input": return side != Sides.right
        "output": return side == Sides.right
    return super._handle_get_data(name, source, source_component, args)

func get_adapter_at(pos: Vector2i, type: String) -> EntityAdapter:
    if pos != Vector2i.ZERO or type != "item": return null
    return entity.adapters["item"]

func get_component_at(pos: Vector2i, rot: int, type: String) -> BuildingComponent:
    if pos != entity.pos: return null
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
    if operation == "drop_item":
        Global.input_handler.call_input_processor("item", "access_and_operate", [self, "drop_item", args])

func _on_building_remote_operation(source: Entity, operation: String, args: Array = []) -> void:
    if source.world != entity.world: return
    if operation == "drop_item":
        var type: String = args[0]
        var pos: Vector2 = to_local(args[1])
        handle_drop_item(source, type, pos)

func handle_drop_item(source: Entity, type: String, pos: Vector2) -> void:
    if not source.has_adapter("inventory"): return
    var inventory = source.get_adapter("inventory") as Inventory
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

func _check_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> bool:
    var item: Item = args[0]
    var source_direction: Directions = args[1]
    # todo
    return true

func _handle_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    var item: Item = args[0]
    var source_direction: Directions = args[1]
    # todo
    return item

func handle_break(unit: BuilderAdapterUnit) -> bool:
    return true

func get_speed() -> float:
    return building.building_type.speed
