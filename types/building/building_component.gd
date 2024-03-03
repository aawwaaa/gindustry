@tool
class_name BuildingComponent
extends Node2D

const DEFAULT_TEXTURE = preload("res://types/building/building_component_default_texture.tres")
enum Sides{ right = 1, down = 2, left = 4, up = 8 }
const SIDE_TO_ROT = [0, 0, 1, 2, 2, 3, 3, 3, 3]

@export_flags("right", "down", "left", "up") var sides: int = 0:
    set(v):
        sides = v
        queue_redraw()

func _get_side_texture(side: Sides) -> Texture2D:
    return DEFAULT_TEXTURE

func _get_side_texture_position(side: Sides) -> Vector2:
    return Vector2(Global.TILE_SIZE / 2 - 8, -8)

func _draw_component(overlay: CanvasItem) -> void:
    for side in Sides.values():
        if not sides & side: continue
        var texture = _get_side_texture(side)
        var position = _get_side_texture_position(side)
        overlay.draw_set_transform(Vector2.ZERO, Tile.to_entity_rot(SIDE_TO_ROT[side]))
        overlay.draw_texture(texture, position)

func draw_component(overlay: CanvasItem) -> void:
    _draw_component(overlay)

func _draw() -> void:
    draw_component(self)

func _ready() -> void:
    queue_redraw()

