class_name BuildingType_Conveyor
extends BuildingType

const ENTITY_SCENE = preload("res://types/buildings/conveyor/conveyor.tscn")
const BUILDING_SHADOW = preload("res://types/buildings/conveyor/conveyor_building_shadow.tscn")

@export var speed: float = 4
@export var animation_speed: float = 8

@export_group("textures", "texture_")
@export var texture_left: Texture2D
@export var texture_left_up: Texture2D
@export var texture_left_down: Texture2D
@export var texture_left_up_down: Texture2D
@export var texture_up: Texture2D
@export var texture_down: Texture2D
@export var texture_up_down: Texture2D

@export var texture_polygon_texture: Texture2D
@export var texture_polygon_texture_offset: Vector2

@export var hframes: int = 1
@export var vframes: int = 1

func _get_default_entity_scene() -> PackedScene:
    return ENTITY_SCENE

func _get_default_building_shadow() -> PackedScene:
    return BUILDING_SHADOW

func _get_rotatable() -> bool:
    return true

