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
    shadow.pos = tile_pos
    shadow.building_config = building_config
    shadow.layer = layer
    shadow_container.add_child(shadow)
    shadow.rot = main_node.rotation
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
    shadow.place(false, entity_id)
    placed.emit()

func destroy() -> void:
    if not shadow:
        should_destroy = true
        return
    should_destroy = false
    shadow.destroy(false, entity_id)
    destroyed.emit()

func _handle_break(unit: BuilderAdapterUnit) -> bool:
    if not accept_access(unit.adapter.entity_node.main_node): return false
    return true

func _handle_destroy() -> void:
    pass

func _can_be_replaced_by(building_type: BuildingType) -> bool:
    return self.building_type._can_be_replaced_by(self, building_type)

func _get_attribute(type: BuildingAttributeType) -> BuildingAttribute:
    return building_type.get_attribute(type)

func get_attribute(type: BuildingAttributeType) -> BuildingAttribute:
    return _get_attribute(type)

func _get_consumers() -> Array[Consumer]:
    return [] as Array[Consumer]

func get_consumers() -> Array[Consumer]:
    return _get_consumers()

func _get_providers() -> Array[Provider]:
    return [] as Array[Provider]

func get_providers() -> Array[Provider]:
    return _get_providers()

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        building_type = Contents.get_content_by_index(stream.get_64()) as BuildingType
        building_config = building_type._load_config(stream)
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_64(building_type.index)
        building_type._save_config(building_config, stream)
    ])
