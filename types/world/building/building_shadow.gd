class_name BuildingShadow
extends Node2D

signal input(event: InputEvent)

var building_type: BuildingType

var layer: int = 0:
    set = set_layer;
@export var floor_collision_mask_begin: int;
@export var floor_collision_mask_end: int;
@export var collision_mask_begin: int;
@export var collision_mask_end: int;
@export var collision: AnimatableBody2D
@export var collision_area: Area2D
@export var floors: Node2D;
@export var display_polygons: Node2D;
@export var display_sprite: Sprite2D;
@export var marks: Node2D;

var world: World
var tiles: PackedVector2Array = []
var polygons_full_points: Array[PackedVector2Array] = []

var build_progress: float:
    set = set_build_progress
var full_build: bool = false
var building_config: Variant:
    get = _get_building_config,
    set = _set_building_config

func _check_build() -> bool:
    if collision_area.get_overlapping_bodies().size() > (1 if build_progress != 0 else 0):
        return false
    var floor_count = 0;
    for area2d in floors.get_children():
        if area2d.get_overlapping_bodies().size() > 0:
            floor_count += 1
    if floor_count < floors.size(): return false
    for tile_pos in tiles:
        var tile = world.get_tile_or_null(tile_pos)
        if not tile.can_build_on(building_type): return false
    return true

func _set_check_build_result(result: bool) -> void:
    if result:
        display_sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)
    else:
        display_sprite.modulate = Color(1.0, 0.2, 0.2, 0.5)

func finish_build() -> void:
    if full_build: return
    build_progress = 1
    full_build = true
    floors.queue_free()
    display_polygons.queue_free()
    display_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_build_progress(v: float) -> void:
    if full_build: return
    build_progress = v
    for id in range(display_polygons.get_child_count()):
        var polygon = display_polygons.get_child(id)
        var base = polygon.polygon[0]
        var points = polygons_full_points[id]
        for point_id in range(points.size()):
            var point = points[point_id]
            polygon.polygon[point_id + 1] = base + point * v
    collision.process_mode = PROCESS_MODE_DISABLED if v == 0 else PROCESS_MODE_INHERIT

func set_layer(v: int) -> void:
    layer = v
    var mask = Entity.get_collision_mask_static(layer,
            collision_mask_begin, collision_mask_end);
    collision.collision_mask = mask
    collision.collision_layer = mask
    collision_area.collision_mask = mask
    collision_area.collision_layer = mask
    if not is_instance_valid(floors): return
    var floor_mask = Entity.get_collision_mask_static(layer,
            floor_collision_mask_begin, floor_collision_mask_end);
    for area2d in floors.get_children():
        area2d.collision_mask = floor_mask
        area2d.collision_layer = floor_mask

func _ready() -> void:
    collision_area.monitorable = false
    for area2d in floors.get_children():
        area2d.monitorable = false
        var pos = (area2d.position / Global.TILE_SIZE) \
                .rotated(global_rotation - world.global_rotation).floor()
        tiles.append(pos)
    for polygon in display_polygons.get_children():
        var base = polygon.polygon[0]
        var diffs = polygon.polygon.slice(1)
        for id in range(diffs.size()):
            diffs[id] = (diffs[id] - base) * 2
        polygons_full_points.append(diffs)

func _get_building_config() -> Variant:
    return building_config

func _set_building_config(config: Variant) -> void:
    building_config = config;

func _on_collision_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
    input.emit(event)
