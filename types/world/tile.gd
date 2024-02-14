class_name Tile
extends RefCounted

enum TileLayer{
    FLOOR_TILE = 0,
    OVERLAY_TILE,
    FLOOR_OVERLAY_TILE,
    MARKER_TILE,
}

const HALF_TILE = Vector2i(Global.TILE_SIZE / 2, Global.TILE_SIZE / 2)

# base
var world: World;
var chunk: Chunk;
var tile_pos: Vector2i;
var tile_chunk_pos: Vector2i;
var has_special_data: bool = false;

# redirect
var enable_redirect: bool = false;
var redirect_world: int = 0;
var redirect_target_tile: Vector2i;

# floor
var floor_type: Floor
var floor_data: Variant = null

# overlay
var overlay_type: Overlay
var overlay_data: Variant = null

# building
var building_ref: int:
    set(v):
        building_ref = v
        set_special_data()
var building: Building:
    get:
        var entity = Entity.get_entity_by_ref_or_null(building_ref)
        return entity if entity is Building else null
var building_shadow: BuildingShadowContainer:
    get:
        var entity = Entity.get_entity_by_ref_or_null(building_ref)
        return entity.main_node \
                if entity and entity.main_node is BuildingShadowContainer \
                else null

static func floor_to_tile_grid(pos: Vector2) -> Vector2i:
    return (pos / Global.TILE_SIZE).floor() * Global.TILE_SIZE

func set_special_data() -> void:
    if has_special_data:
        return;
    has_special_data = true;
    Game.create_temp_tile();
    chunk.tiles[tile_pos] = self;

func load_from_tilemap() -> void:
    var floors = world.get_floors_node();
    var floor_source_id = floors.get_cell_source_id(TileLayer.FLOOR_TILE, tile_pos)
    if floor_source_id == -1:
        floor_type = null;
    else:
        var floor_coords = floors.get_cell_atlas_coords(TileLayer.FLOOR_TILE, tile_pos);
        floor_type = Floor.source_id_to_coords_to_content[floor_source_id][floor_coords];
    var overlay_source_id = floors.get_cell_source_id(TileLayer.OVERLAY_TILE, tile_pos)
    if overlay_source_id == -1:
        overlay_type = null;
    else:
        var overlay_coords = floors.get_cell_atlas_coords(TileLayer.OVERLAY_TILE, tile_pos);
        overlay_type = Overlay.source_id_to_coords_to_content[overlay_source_id][overlay_coords];

func _on_world_layer_changed(_layer: int, _from: int) -> void:
    if floor_type:
        floor_type._update_floor(self)
    if overlay_type:
        overlay_type._update_overlay(self)

func get_layer() -> int:
    return world.layer

func init_tile(chunk_inst: Chunk, pos: Vector2i) -> void:
    self.chunk = chunk_inst;
    self.world = chunk.world;
    self.tile_chunk_pos = pos;
    self.tile_pos = pos + chunk.chunk_base_pos;

func set_floors_tilemap(layer: TileLayer, source_id: int, tile_coords: Vector2i, tile_alter_id: int):
    world.get_floors_node().set_cell(layer, tile_pos, source_id, tile_coords, tile_alter_id);

func set_floor(new_floor_type: Floor, new_floor_data = new_floor_type._init_floor_data(self) if new_floor_type else null) -> void:
    if floor_type:
        floor_type._remove_floor(self)
    self.floor_type = new_floor_type;
    self.floor_data = new_floor_data;
    if floor_type:
        floor_type._update_floor(self)
    if floor_data != null:
        set_special_data()

func set_overlay(new_overlay_type: Overlay, new_overlay_data = new_overlay_type._init_overlay_data(self) if new_overlay_type else null) -> void:
    if overlay_type:
        overlay_type._remove_overlay(self)
    self.overlay_type = new_overlay_type;
    self.overlay_data = new_overlay_data;
    if overlay_type:
        overlay_type._update_overlay(self)
    if overlay_data != null:
        set_special_data()

func can_build_on(building_type: BuildingType) -> bool:
    if floor_type and not floor_type.can_build_on(self, building_type): return false
    if overlay_type and not overlay_type.can_build_on(self, building_type): return false
    if building and not building._can_be_replaced_by(building_type): return false
    if building_shadow: return false
    return true

func clear_building() -> void:
    if building_shadow:
        var shadow = building_shadow
        shadow.destroy()
        building_ref = 0
        return
    var inst = building
    inst.destroy()
    inst.remove()

func set_building(type: BuildingType, rotation: float = 0, config: Variant = type._get_default_config() if type else null) -> Building:
    if building: clear_building()
    if not type: return
    var inst = type.create_entity()
    inst.main_node.position = tile_pos * Global.TILE_SIZE + HALF_TILE
    inst.main_node.rotation = rotation
    inst.building_config = config
    world.add_entity(inst)
    inst.place()
    return inst

func set_building_shadow(type: BuildingType, rotation: float = 0, config: Variant = type._get_default_config() if type else null) -> BuildingShadowContainer:
    if building: clear_building()
    if not type: return
    var container = Builtin.entity["building_shadow_container"].create_entity().main_node
    container.building_type = type
    container.position = tile_pos * Global.TILE_SIZE + HALF_TILE
    container.rotation = rotation
    world.add_entity(container.get_entity())
    container.shadow.building_config = config
    container.place()
    return container

func set_redirect(target: World, pos: Vector2i = Vector2i.ZERO) -> void:
    if target == null:
        enable_redirect = false;
        return;
    enable_redirect = true;
    redirect_world = target.world_id;
    redirect_target_tile = pos;
    set_special_data();

const current_data_version = 1;

func load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return;
    has_special_data = true;
    enable_redirect = stream.get_8() == 1;
    if enable_redirect:
        redirect_world = stream.get_32();
        redirect_target_tile = stream.get_var();
    floor_type = Contents.get_content_by_index(stream.get_32()) as Floor;
    if floor_type:
        floor_type.load_data(self, stream);
        floor_type._update_floor(self);
    overlay_type = Contents.get_content_by_index(stream.get_32()) as Overlay;
    if overlay_type:
        overlay_type.load_data(self, stream);
        overlay_type._update_overlay(self);
    # version 1
    if version < 1: return;
    building_ref = stream.get_64()

func save_data(stream: Stream) -> void:
    stream.store_16(current_data_version);
    # version 0
    stream.store_8(1 if enable_redirect else 0);
    if enable_redirect:
        stream.store_32(redirect_world);
        stream.store_var(redirect_target_tile, true);
    if not floor_type:
        stream.store_32(0)
    else:
        stream.store_32(floor_type.index);
        floor_type.save_data(self, stream);
    if not overlay_type:
        stream.store_32(0)
    else:
        stream.store_32(overlay_type.index);
        overlay_type.save_data(self, stream);
    # version 1
    stream.store_64(building_ref)
