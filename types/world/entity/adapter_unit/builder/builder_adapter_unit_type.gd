class_name BuilderAdapterUnitType
extends AdapterUnitType

@export var build_range: Shape2D
@export var build_range_layer_begin: int = 0
@export var build_range_layer_end: int = 0

@export var build_speed: float = 1

func _get_adapter_unit_scene() -> PackedScene:
    return load("res://types/world/entity/adapter_unit/builder/builder_adapter_unit.tscn")
