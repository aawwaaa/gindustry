class_name Building
extends Entity

signal placed()
signal destroyed()

@export var shadow_container: Node2D

var building_type: BuildingType:
    get: return entity_type if entity_type is BuildingType else null
var building_config: Variant
var shadow: BuildingShadow

var should_place: bool = false
var should_destroy: bool = false

func _ready() -> void:
    super._ready()

    layer_changed.connect(_on_layer_changed)
    shadow = building_type.create_shadow()
    shadow.world = world
    shadow.building_config = building_config
    shadow.layer = layer
    shadow_container.add_child(shadow)
    shadow.finish_build()

    if should_place: place()
    if should_destroy: destroy()

func _on_layer_changed(layer: int, from: int) -> void:
    if not shadow: return
    shadow.layer = layer

func place() -> void:
    if not shadow:
        should_place = true
        return
    should_place = false
    for pos in shadow.tiles:
        var tile = world.get_tile_or_null(tile_pos + pos)
        if not tile: continue
        tile.building_ref = entity_id
    placed.emit()

func destroy() -> void:
    if not shadow:
        should_destroy = true
        return
    should_destroy = false
    for pos in shadow.tiles:
        var tile = world.get_tile_or_null(tile_pos + pos)
        if not tile: continue
        tile.building_ref = 0
    destroyed.emit()

func _can_be_replaced_by(building_type: BuildingType) -> bool:
    return self.building_type._can_be_replaced_by(self, building_type)

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        building_type = Contents.get_content_by_index(stream.get_64()) as BuildingType
        building_config = building_type.load_config(stream)
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_64(building_type.index)
        building_type._save_config(building_config, stream)
    ])
