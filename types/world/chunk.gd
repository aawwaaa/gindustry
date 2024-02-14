class_name Chunk
extends RefCounted

# bases
var world: World
var chunk_pos: Vector2i;
var chunk_base_pos: Vector2i;

var tiles = {};

func _ready() -> void:
    world.layer_changed.connect(_on_world_layer_changed)

func _on_world_layer_changed(layer: int, from: int) -> void:
    for x in range(Global.CHUNK_SIZE):
        for y in range(Global.CHUNK_SIZE):
            get_tile(Vector2i(x, y))._on_world_layer_changed(layer, from);

func get_layer() -> int:
    return world.layer;

func get_tile(tile_chunk_pos: Vector2i, follow_redirect = true) -> Tile:
    if not tiles.has(tile_chunk_pos):
        if tile_chunk_pos[0] < 0 or tile_chunk_pos[1] < 0 or tile_chunk_pos[0] >= Global.CHUNK_SIZE or tile_chunk_pos[1] >= Global.CHUNK_SIZE:
            return null;
        Game.temp_tile.init_tile(self, tile_chunk_pos);
        Game.temp_tile.load_from_tilemap();
        return Game.temp_tile;
    var tile = tiles[tile_chunk_pos]
    if follow_redirect and tile.enable_redirect:
        return Game.worlds[tile.redirect_world].get_tile_or_null(tile.redirect_target_tile)
    return tile;

func init_chunk(world_inst: World, pos: Vector2i) -> void:
    self.world = world_inst;
    self.chunk_pos = pos;
    self.chunk_base_pos = pos * Global.CHUNK_SIZE;

func init_tile_for(pos: Vector2i, data: Stream = null) -> Tile:
    if tiles.has(pos):
        tiles[pos].queue_free();
    var tile = Tile.new();
    tile.init_tile(self, pos);
    tiles[pos] = tile;
    if data:
        tile.load_data(data);
    return tile;

const current_data_version = 0

func load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return;
    for x in range(Global.CHUNK_SIZE):
        for y in range(Global.CHUNK_SIZE):
            if stream.get_8() == 1:
                init_tile_for(Vector2i(x, y), stream);
            else:
                Game.temp_tile.init_tile(self, Vector2i(x, y))
                Game.temp_tile.load_data(stream);

func save_data(stream: Stream) -> void:
    stream.store_16(current_data_version)
    # version 0
    for x in range(Global.CHUNK_SIZE):
        for y in range(Global.CHUNK_SIZE):
            var tile = get_tile(Vector2i(x, y))
            stream.store_8(1 if tile.has_special_data else 0)
            tile.save_data(stream)
