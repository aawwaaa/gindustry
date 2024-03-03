class_name Building
extends Entity

signal placed()
signal destroyed()

@export var shadow_container: Node2D
@export var has_building_adapters: bool = false

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
    shadow.finish_build(self)

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

func handle_break(unit: BuilderAdapterUnit) -> bool:
    return _handle_break(unit)

func _handle_destroy() -> void:
    pass

func handle_destroy() -> void:
    _handle_destroy()

func _can_be_replaced_by(building_type: BuildingType) -> bool:
    return self.building_type._can_be_replaced_by(self, building_type)

func can_be_replaced_by(building_type: BuildingType) -> bool:
    return _can_be_replaced_by(building_type)

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

func _get_adapter_at(pos: Vector2i, rot: int, type: String) -> EntityAdapter:
    return null

func get_adapter_at(pos: Vector2i, rot: int, type: String) -> EntityAdapter:
    if not has_building_adapters: return null
    var delta = pos - shadow.pos
    var shadow_rotation = Tile.to_entity_rot(shadow.rot)
    var rotated = delta.rotated(-shadow_rotation)
    return _get_adapter_at(rotated, shadow_rotation, type)

func get_component_at(pos: Vector2i, rot: int, type: String) -> BuildingComponent:
    if not shadow.pos_to_component.has(pos): return null
    if not shadow.pos_to_component[pos].has(type): return null
    var component: BuildingComponent = shadow.pos_to_component[pos][type]
    rot = (rot + 3 - shadow.rot) % 4
    var side = BuildingComponent.ROT_TO_SIDE[rot]
    if not component.has_side(side): return null
    return component

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
