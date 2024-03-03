class_name Building_Conveyor
extends BuildingComponent

enum Directions{
    left, right, far, close, centre
}

func has_side(side: Sides) -> bool:
    return side != Sides.right

func _get_transfer_type() -> String:
    return "conveyor"

func _process_update(delta: float) -> void:
    pass

func _handle_get_data(name: String) -> Variant:
    return null

func _check_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> bool:
    var item: Item = args[0]
    var target_direction: Directions = args[1]
    var source_direction: Directions = args[2]
    return true

func _handle_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    var item: Item = args[0]
    var target_direction: Directions = args[1]
    var source_direction: Directions = args[2]
    return item

