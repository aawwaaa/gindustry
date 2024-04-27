class_name BuildingType_ConveyorJunction
extends BuildingType_ConveyorModule

const MODULE_SCENE = preload("res://types/buildings/conveyor/modules/junction/conveyor_junction.tscn")

func _get_default_entity_scene() -> PackedScene:
    return MODULE_SCENE

