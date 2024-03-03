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

var building: Building
var main_node: Node2D:
    get: return building.main_node

var pos: Vector2i
var rot: int

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

func init_component(pos: Vector2i, rot: int) -> void:
    self.pos = pos
    self.rot = rot

func _get_transfer_type() -> String:
    return "none"

func get_transfer_type() -> String:
    return _get_transfer_type()

func _process_update(delta: float) -> void:
    pass

func _handle_get_data(name: String) -> Variant:
    return null

func get_data(name: String) -> Variant:
    return _handle_get_data(name)

func _check_transfer(name: String, args: Array = []) -> bool:
    return true

func check_transfer(name: String, args: Array = []) -> bool:
    if name != get_transfer_type(): return false
    return _check_transfer(name, args)

func _handle_transfer(name: String, args: Array = []) -> Variant:
    return null

func handle_transfer(name: String, args: Array = []) -> Variant:
    return _handle_transfer(name, args)

func _process(delta: float) -> void:
    if Engine.is_editor_hint(): return
    _process_update(delta)
