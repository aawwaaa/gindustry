class_name World
extends Node2D

signal layer_changed(layer: int, from: int);

var chunk_load_source: ChunkLoadSource;
var world_id: int;
var parent_world: World;

var layer: int = 0:
    set = set_layer;
var chunks = {};
var entities = {};
var root_world = false;

var collision_layer: int:
    get: return 1 << layer

static var scene = preload("res://types/world/world.tscn")
static var temp_physics_body_shape = preload("res://types/world/temp_physics_body_collision_shape.tres")

@onready var temp_nodes = %TempNodes

static func create() -> World:
    return scene.instantiate()

func _enter_tree() -> void:
    Game.worlds[world_id] = self;
    if root_world:
        Game.root_world = self;
        name = "World#" + str(world_id)

func _exit_tree() -> void:
    Game.worlds.erase(world_id)
    if root_world:
        Game.root_world = null

func _ready() -> void:
    return

func create_temp_physics_body(position: Vector2) -> Area2D:
    var collision_shape = CollisionShape2D.new()
    collision_shape.shape = temp_physics_body_shape
    var body = Area2D.new();
    body.add_child(collision_shape)
    body.collision_layer = collision_layer
    body.position = position
    temp_nodes.add_child(body);
    return body

func set_layer(value: int) -> void:
    var old = layer;
    layer = value;
    layer_changed.emit(value, old);

func get_chunk_or_null(chunk_pos: Vector2i) -> Chunk:
    if not chunks.has(chunk_pos):
        return null;
    return chunks[chunk_pos];

func get_chunk(chunk_pos: Vector2i) -> Chunk:
    var chunk = get_chunk_or_null(chunk_pos);
    if chunk:
        return chunk
    if not chunk_load_source:
        return null;
    if chunk_load_source:
        chunk_load_source.world = self;
    @warning_ignore("redundant_await")
    chunk = await chunk_load_source._load_chunk(chunk_pos)
    if not chunk:
        return null;
    chunks[chunk_pos] = chunk;
    return chunk;

func get_chunk_tile_or_null(tile_pos: Vector2i) -> Chunk:
    var pos = (Vector2(tile_pos) / Global.CHUNK_SIZE).floor()
    return get_chunk_or_null(pos)

func get_chunk_tile(tile_pos: Vector2i) -> Chunk:
    return await get_chunk((Vector2(tile_pos) / Global.CHUNK_SIZE).floor())

func get_tile_or_null(tile_pos: Vector2i) -> Tile:
    var chunk = get_chunk_tile_or_null(tile_pos);
    if not chunk:
        return null;
    return chunk.get_tile(Vector2i(tile_pos.x & (Global.CHUNK_SIZE - 1), \
            tile_pos.y & (Global.CHUNK_SIZE - 1)));

func get_tile(tile_pos: Vector2i) -> Tile:
    var chunk = await get_chunk_tile(tile_pos);
    if not chunk:
        return null;
    return chunk.get_tile(Vector2i(tile_pos.x & (Global.CHUNK_SIZE - 1), \
            tile_pos.y & (Global.CHUNK_SIZE - 1)));

func get_floors_node() -> TileMap:
    return %Floors;

func get_entities_node() -> Node2D:
    return %Entities;

func init_chunk_for(pos: Vector2i, stream: Stream = null) -> Chunk:
    if chunks.has(pos):
        chunks[pos].queue_free();
    var chunk = Chunk.new();
    chunk.init_chunk(self, pos);
    chunks[pos] = chunk;
    if stream:
        chunk.load_data(stream)
    return chunk

func create_sub_world() -> World:
    var world = World.scene.instantiate();
    world.world_id = Game.world_inc_id;
    Game.world_inc_id += 1;
    world.root_world = false;
    Game.worlds[world.world_id] = world;
    return world;

func add_entity(entity: Entity) -> void:
    entities[entity.entity_id] = entity
    entity.set_world(self)

func remove_entity(entity: Entity) -> void:
    entities.erase(entity.entity_id)

func add_temp_node(node: Node2D) -> void:
    %TempNodes.add_child(node)

func remove_temp_node(node: Node2D) -> void:
    %TempNodes.remove_child(node)

func get_temp_node(node_path: NodePath) -> Node2D:
    return %TempNodes.get_node(node_path)

const current_data_version = 0;

func load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return;
    world_id = stream.get_32();
    Game.worlds[world_id] = self;
    root_world = stream.get_8() == 1;
    if not root_world:
        parent_world = Game.worlds[stream.get_32()];
    for _1 in range(stream.get_32()):
        var pos = stream.get_var();
        init_chunk_for(pos, stream);
    for _1 in range(stream.get_64()):
        var entity = Entity.load_from(stream)
        entities[entity.entity_id] = entity;
        entity.set_world(self)

func save_data(stream: Stream) -> void:
    stream.store_16(current_data_version);
    # version 0
    stream.store_32(world_id);
    stream.store_8(1 if root_world else 0)
    if not root_world:
        stream.store_32(parent_world.world_id)
    stream.store_32(chunks.size());
    for pos in chunks.keys():
        stream.store_var(pos);
        chunks[pos].save_data(stream);
    stream.store_64(entities.size())
    for entity in entities.values():
        entity.save_to(stream)
