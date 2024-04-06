class_name TileOre
extends Resource

@export var collect_speed: float = 1

func _get_collect_speed() -> float:
    return collect_speed

func get_collect_speed() -> float:
    return _get_collect_speed()

func _get_type() -> TileOreType:
    return null

func get_type() -> TileOreType:
    return _get_type()

