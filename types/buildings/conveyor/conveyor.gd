class_name EntityNode_Conveyor
extends BuildingComponent

enum Directions{
    left, right, center
}
enum DisplayDirectons{
    left = 1, up = 2, down = 4
}

@export var entity: Building;
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

