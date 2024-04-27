@tool
class_name BuildingComponent
extends Node2D

const DEFAULT_TEXTURE = preload("res://types/building/building_component_default_texture.tres")
enum Sides{ right = 1, down = 2, left = 4, up = 8 }
const SIDE_TO_ROT = [0, 0, 1, 2, 2, 3, 3, 3, 3]
const ROT_TO_SIDE = [1, 2, 4, 8]

static func revert_sides(sides: int) -> int:
    var reverted = sides << 2
    reverted = reverted & 0xf | (reverted >> 4)
    return reverted

static func rotate_sides(sides: int, rot: int) -> int:
    if rot < 0:
        var rotated = sides >> rot
        return rotated | (sides & (0xf << rot)) >> rot
    var rotated = sides << rot
    rotated = rotated & 0xf | (rotated >> 4)
    return rotated

static func revert_rot(rot: int) -> int:
    return (rot+2) % 4

@export_flags("right", "down", "left", "up") var sides: int = 0:
    set(v):
        sides = v
        queue_redraw()

var building: Building
var main_node: Node2D:
    get: return building.main_node

var pos: Vector2i
var rot: int:
    get: return building.shadow.rot

func apply_rot(rot: int) -> int:
    return (rot + self.rot) % 4

func unapply_rot(rot: int) -> int:
    return (rot + 4 - self.rot) % 4

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

func init_component(pos: Vector2i) -> void:
    self.pos = pos

func _has_side(side: Sides) -> bool:
    return (sides & side) != 0

func has_side(side: Sides) -> bool:
    return _has_side(side)

func _get_transfer_type() -> String:
    return "none"

func get_transfer_type() -> String:
    return _get_transfer_type()

func _process_update(delta: float) -> void:
    pass

func _handle_get_data(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    return null

func get_data(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    return _handle_get_data(name, source, source_component, args)

func _check_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> bool:
    return true

func check_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> bool:
    if name != get_transfer_type(): return false
    return _check_transfer(name, source, source_component, args)

func _handle_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    return null

func handle_transfer(name: String, source: Building, source_component: BuildingComponent, args: Array = []) -> Variant:
    return _handle_transfer(name, source, source_component, args)

func get_tile(side: Sides) -> Tile:
    var rot = apply_rot(SIDE_TO_ROT[side])
    var base = building.world.get_tile_or_null(pos)
    return base.get_near_tile(rot)

func get_component(side: Sides, type: String = get_transfer_type(), ignore_side = false) -> BuildingComponent:
    var rot = apply_rot(SIDE_TO_ROT[side])
    var tile = get_tile(side)
    if not tile or not tile.building: return null
    return tile.building.get_component_at(tile.tile_pos, revert_rot(rot), type, ignore_side)

func get_building_side(building: Building, component: BuildingComponent = null) -> Sides:
    var pos = component.pos if component else building.pos
    var rot = Vector2(self.pos).angle_to_point(Vector2(pos))
    return ROT_TO_SIDE[unapply_rot(Tile.to_tile_rot(rot))]

func _process(delta: float) -> void:
    if Engine.is_editor_hint(): return
    _process_update(delta)
