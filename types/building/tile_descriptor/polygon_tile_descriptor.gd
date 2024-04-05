@tool
class_name PolygonTileDescriptor
extends TileDescriptorChild

@export var polygon: PackedVector2Array = PackedVector2Array():
    set(v): polygon = v; queue_redraw()

func _draw() -> void:
    draw_colored_polygon(polygon, Color(0.5, 0.5, 0.5, 0.5))

func _ready() -> void:
    queue_redraw()

func _get_tiles() -> Array[Vector2i]:
    var leftest = Vector2.ZERO
    var rightest = Vector2.ZERO
    for point in polygon:
        leftest = leftest.min(point)
        rightest = rightest.max(point)
    var out = []
    for x in range(floor(leftest.x / Global.TILE_SIZE), floor(rightest.x / Global.TILE_SIZE) + 1):
        for y in range(floor(leftest.y / Global.TILE_SIZE), floor(rightest.y / Global.TILE_SIZE) + 1):
            var tile = Vector2(Vector2i(x, y) * Global.TILE_SIZE_VECTOR)
            if Geometry2D.is_point_in_polygon(tile, polygon):
                out.append(Vector2i(x, y))
    return out
