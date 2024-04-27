class_name EffectityField
extends Node2D

@export var field_shape: Shape2D
@export var field_effectity: float = 1

func _ready() -> void:
    %CollisionShape2D.shape = field_shape

func get_field_effectity() -> float:
    return field_effectity
