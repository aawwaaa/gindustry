class_name BuildingType_ConveyorModule
extends BuildingType

const ENTITY_SCENE = preload("res://types/buildings/conveyor/modules/conveyor_module.tscn")
const BUILDING_SHADOW = preload("res://types/buildings/conveyor/modules/conveyor_module_building_shadow.tscn")

@export var conveyor_type: BuildingType_Conveyor

@export_group("textures", "texture_")
@export var texture_texture: Texture2D
@export var texture_z_index: int = 8

@export var texture_polygon_texture: Texture2D
@export var texture_polygon_texture_offset: Vector2

func _get_default_entity_scene() -> PackedScene:
    return ENTITY_SCENE

func _get_default_building_shadow() -> PackedScene:
    return BUILDING_SHADOW

func _get_rotatable() -> bool:
    return true

