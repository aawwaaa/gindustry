class_name BuildingShadowContainer
extends Node2D

@export var entity: Entity

var building_type: BuildingType
var building_config: Variant
var shadow: BuildingShadow

var should_place: bool = false
var should_destroy: bool = false

func get_entity() -> Entity:
    return entity

func _on_entity_layer_changed(layer: int, from: int) -> void:
    if not shadow: return
    shadow.layer = layer

func _ready() -> void:
    shadow = building_type.create_shadow()
    shadow.world = entity.world
    shadow.building_config = building_config
    _on_entity_layer_changed(entity.layer, -1)
    add_child(shadow)
    if should_place: place()
    if should_destroy: destroy()

func place() -> void:
    if not shadow: 
        should_place = true
        return
    should_place = false
    for pos in shadow.tiles:
        var tile = entity.world.get_tile_or_null(entity.tile_pos + pos)
        if not tile: continue
        tile.building_ref = entity.entity_id 

func destroy() -> void:
    if not shadow:
        should_destroy = true
        return
    should_destroy = false
    for pos in shadow.tiles:
        var tile = entity.world.get_tile_or_null(entity.tile_pos + pos)
        if not tile: continue
        tile.building_ref = 0
    entity.remove()

const current_data_version: int = 0

func _on_entity_on_load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return;
    building_type = Contents.get_content_by_index(stream.get_64()) as BuildingType
    building_config = building_type._load_config(stream)

func _on_entity_on_save_data(stream: Stream) -> void:
    stream.store_16(current_data_version);
    # version 0
    stream.store_64(building_type.index)
    building_type._save_config(building_config, stream)
