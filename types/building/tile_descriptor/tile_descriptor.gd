class_name TileDescriptor
extends Node2D

func get_tiles() -> Array[Vector2i]:
    var out = []
    for child in find_children("", "TileDescriptorChild"):
        out += child.get_tiles()
    return []

func get_tiles_rotated(rotation: int) -> Array[Vector2i]:
    var out = []
    for tile in get_tiles():
        out.append(Vector2(tile).rotated(Tile.to_entity_rot(rotation)).round())
    return out
