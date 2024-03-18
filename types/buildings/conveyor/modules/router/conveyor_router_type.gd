class_name BuildingType_ConveyorRouter
extends BuildingType_ConveyorModule

const MODULE_SCENE = preload("res://types/buildings/conveyor/modules/router/conveyor_router.tscn")

func _get_default_entity_scene() -> PackedScene:
    return MODULE_SCENE

func _get_rotatable() -> bool:
    return false

