class_name TileOre
extends Resource

func _get_collect_speed() -> float:
    return 1

func get_collect_speed() -> float:
    return _get_collect_speed()

func _get_type() -> TileOreType:
    return null

func get_type() -> TileOreType:
    return _get_type()

func _has_panel(tile: Tile, ore_type: String) -> bool:
    return false

func _create_panel(tile: Tile, ore_type: String) -> Control:
    return null

func add_panel_to(tile: Tile, ore_type: String, control: Control) -> void:
    if not _has_panel(tile, ore_type): return
    control.add_child(_create_panel(tile, ore_type))
