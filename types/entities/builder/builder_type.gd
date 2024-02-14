class_name BuilderType
extends EntityType

@export var build_range: Shape2D
@export var build_range_layer_begin: int = 0
@export var build_range_layer_end: int = 0
@export var build_speed: float = 1;

func _init() -> void:
    entity_scene = load("res://types/entities/builder/builder.tscn")
