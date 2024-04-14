class_name BuildingType_ConveyorSorter
extends BuildingType_ConveyorModule

const MODULE_SCENE = preload("res://types/buildings/conveyor/modules/sorter/conveyor_sorter.tscn")

func _get_default_entity_scene() -> PackedScene:
    return MODULE_SCENE

func _get_rotatable() -> bool:
    return true

