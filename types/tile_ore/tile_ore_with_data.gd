class_name TileOreWithData
extends TileOre

@export var auto_remove: bool = true

func _init_ore_data(_tile: Tile, _ore_type: String) -> Variant:
    return null

func _load_data(_tile: Tile, _ore_type: String, _stream: Stream) -> void:
    pass

func _save_data(_tile: Tile, _ore_type: String, _stream: Stream) -> void:
    pass

func get_data(tile: Tile, ore_type: String) -> Variant:
    if ore_type == "floor": return tile.floor_ore_data
    if ore_type == "overlay": return tile.overlay_ore_data
    return null

func set_data(tile: Tile, ore_type: String, data: Variant) -> void:
    if ore_type == "floor": tile.floor_ore_data = data
    if ore_type == "overlay": tile.overlay_ore_data = data

func remove_tile_ore(tile: Tile, ore_type: String) -> void:
    if not auto_remove: return
    if ore_type == "floor": tile.set_floor(null)
    if ore_type == "overlay": tile.set_overlay(null)
