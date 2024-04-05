class_name TileDescriptorChild
extends Node2D

func _get_tiles() -> Array[Vector2i]:
    return []

func get_tiles() -> Array[Vector2i]:
    var out = []
    var offset = ((global_position - owner.global_position) / Global.TILE_SIZE).round()
    for tile in _get_tiles():
        out += tile + offset
    return out
