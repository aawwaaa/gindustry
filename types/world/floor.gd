class_name Floor
extends Content

const FLOOR_TYPE = preload("res://contents/content_types/floor.tres")
const FLOORS = preload("res://types/world/floors.tres")

@warning_ignore("integer_division")
const WHOLE_TILE_POLYGON_POINTS = [
    Vector2(- (Global.TILE_SIZE / 2), - (Global.TILE_SIZE / 2)),
    Vector2((Global.TILE_SIZE / 2), - (Global.TILE_SIZE / 2)),
    Vector2((Global.TILE_SIZE / 2), (Global.TILE_SIZE / 2)),
    Vector2((Global.TILE_SIZE / 2), - (Global.TILE_SIZE / 2)),
]

var tile_source_id: int;

@export var tile_coords: Vector2i;
var tile_alter_ids: Array[int] = [];

static var source_id_to_coords_to_content = {}

@export var tile_ores: Array[TileOre];
@export var tile_ore_with_data: TileOreWithData;

var tile_ores_indexed: Dictionary = {};

func _init_floor_data(_tile: Tile) -> Variant:
    return null;

func _update_floor(tile: Tile) -> void:
    tile.set_floors_tilemap(Tile.TileLayer.FLOOR_TILE, tile_source_id, \
            tile_coords, tile_alter_ids[tile.get_layer()])

func _remove_floor(tile: Tile) -> void:
    tile.set_floors_tilemap(Tile.TileLayer.FLOOR_TILE, -1, Vector2i(-1, -1), -1);

func _load_data(_tile: Tile, _stream: Stream, _data_version: int) -> void:
    pass

func _save_data(_tile: Tile, _stream: Stream) -> void:
    pass

func _get_current_version(_tile: Tile) -> int:
    return 0

func load_data(tile: Tile, stream: Stream) -> void:
    if tile_ore_with_data:
        tile_ore_with_data._load_data(tile, "floor", stream)
    var version = stream.get_16();
    _load_data(tile, stream, version)

func save_data(tile: Tile, stream: Stream) -> void:
    if tile_ore_with_data:
        tile_ore_with_data._save_data(tile, "floor", stream)
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

func get_tile_ore(type: TileOreType) -> TileOre:
    return _get_tile_ore(type)

func _should_show_panel(tile: Tile) -> bool:
    return tile_ore_with_data != null or tile_ores.size() > 0

func should_show_panel(tile: Tile) -> bool:
    return _should_show_panel(tile)

func _create_panel_node(tile: Tile) -> Control:
    return null

func create_panel_node(tile: Tile) -> Control:
    return _create_panel_node(tile)

func add_panels_to(tile: Tile, control: Control) -> void:
    var node = create_panel_node(tile)
    if node: control.add_child(node)
    if tile_ore_with_data:
        tile_ore_with_data.add_panel_to(tile, "floor", control)
    for tile_ore in tile_ores:
        tile_ore.add_panel_to(tile, "floor", control)

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "Floor")

func apply_mod(mod_inst: Mod) -> void:
    super.apply_mod(mod_inst);
    for tile_ore in tile_ores:
        tile_ores_indexed[tile_ore.get_type()] = tile_ore

func _get_content_type() -> ContentType:
    return FLOOR_TYPE

func _content_registed() -> void:
    if not source_id_to_coords_to_content.has(tile_source_id):
        source_id_to_coords_to_content[tile_source_id] = {}
    source_id_to_coords_to_content[tile_source_id][tile_coords] = self
