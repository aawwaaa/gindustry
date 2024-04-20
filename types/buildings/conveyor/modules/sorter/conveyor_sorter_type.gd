class_name BuildingType_ConveyorSorter
extends BuildingType_ConveyorModule

const MODULE_SCENE = preload("res://types/buildings/conveyor/modules/sorter/conveyor_sorter.tscn")
const SHADOW_SCENE = preload("res://types/buildings/conveyor/modules/sorter/conveyor_sorter_building_shadow.tscn")

@export_group("textures", "texture_")
@export var texture_blacklist_texture: Texture2D = null

func _get_default_entity_scene() -> PackedScene:
    return MODULE_SCENE

func _get_default_building_shadow() -> PackedScene:
    return SHADOW_SCENE

func _get_rotatable() -> bool:
    return true
