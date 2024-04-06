class_name Overlay
extends Content

const OVERLAY_TYPE = preload("res://contents/content_types/overlay.tres")
var tile_source_id: int;

@export var tile_coords: Vector2i;
var tile_alter_ids: Array[int] = [];

static var source_id_to_coords_to_content = {}

@export var tile_ores: Array[TileOre];
@export var tile_ore_with_data: TileOreWithData;

var tile_ores_indexed: Dictionary = {};

func _init_overlay_data(_tile: Tile) -> Variant:
    return null;

func _update_overlay(tile: Tile) -> void:
    tile.set_floors_tilemap(Tile.TileLayer.OVERLAY_TILE, tile_source_id, \
            tile_coords, tile_alter_ids[tile.get_layer()])

func _remove_overlay(tile: Tile) -> void:
    tile.set_floors_tilemap(Tile.TileLayer.OVERLAY_TILE, -1, Vector2i(-1, -1), -1);

func _load_data(_tile: Tile, _stream: Stream, _data_version: int) -> void:
    pass

func _save_data(_tile: Tile, _stream: Stream) -> void:
    pass

func _get_current_version(_tile: Tile) -> int:
    return 0

func load_data(tile: Tile, stream: Stream) -> void:
    if tile_ore_with_data:
        tile_ore_with_data._load_data(tile, "overlay", stream)
    var version = stream.get_16();
    _load_data(tile, stream, version)

func save_data(tile: Tile, stream: Stream) -> void:
    if tile_ore_with_data:
        tile_ore_with_data._save_data(tile, "overlay", stream)
    stream.store_16(_get_current_version(tile));
    _save_data(tile, stream)

func _can_build_on(tile: Tile, building_type: BuildingType) -> bool:
    return true

func can_build_on(tile: Tile, building_type: BuildingType) -> bool:
    return _can_build_on(tile, building_type)

func _get_tile_ore(type: TileOreType) -> TileOre:
    if tile_ore_with_data and tile_ore_with_data.get_type() == type:
        return tile_ore_with_data
    if tile_ores_indexed.has(type): return tile_ores_indexed[type]
    return null

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "Overlay")

func apply_mod(mod_inst: Mod) -> void:
    super.apply_mod(mod_inst);
    for tile_ore in tile_ores:
        tile_ores_indexed[tile_ore.get_type()] = tile_ore

func _get_content_type() -> ContentType:
    return OVERLAY_TYPE

func _content_registed() -> void:
    if not source_id_to_coords_to_content.has(tile_source_id):
        source_id_to_coords_to_content[tile_source_id] = {}
    source_id_to_coords_to_content[tile_source_id][tile_coords] = self
