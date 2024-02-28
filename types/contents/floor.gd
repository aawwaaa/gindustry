class_name Floor
extends Content

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
    var version = stream.get_16();
    _load_data(tile, stream, version)

func save_data(tile: Tile, stream: Stream) -> void:
    stream.store_16(_get_current_version(tile));
    _save_data(tile, stream)

func can_build_on(tile: Tile, building_type: BuildingType) -> bool:
    return true

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "Floor")

func apply_mod(mod_inst: Mod) -> void:
    super.apply_mod(mod_inst);

func _get_content_type() -> String:
    return "floor"

func _content_registed() -> void:
    if not source_id_to_coords_to_content.has(tile_source_id):
        source_id_to_coords_to_content[tile_source_id] = {}
    source_id_to_coords_to_content[tile_source_id][tile_coords] = self
