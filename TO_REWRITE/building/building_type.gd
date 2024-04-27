class_name BuildingType
extends EntityType

const BUILDING_TYPE = preload("res://contents/content_types/building.tres")

@export var shadow: PackedScene:
    get: return shadow if shadow else _get_default_building_shadow()

@export var building_category: BuildingCategory:
    get: return building_category if building_category else _get_default_building_category();
@export var requirements: Array[PackedItemStack] = []

@export var attributes: Array[BuildingAttribute] = []
var attributes_dict: Dictionary = {}

var requirements_cache: Array[Item] = []

func _get_default_building_shadow() -> PackedScene:
    return null

func get_requirements() -> Array[Item]:
    if requirements_cache.size() != 0: return requirements_cache
    var array: Array[Item] = []
    for item in requirements:
        array.append(item.get_item())
    requirements_cache = array
    return array

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "building")

func _get_content_type() -> ContentType:
    return BUILDING_TYPE

func create_shadow() -> BuildingShadow:
    var inst: BuildingShadow = shadow.instantiate()
    inst.building_type = self
    return inst

func create_entity(init: bool = true) -> Building:
    var entity = super.create_entity(init)
    entity.building_type = self
    return entity

func apply_mod(mod_inst: Mod) -> void:
    super.apply_mod(mod_inst)
    building_category.building_types.append(self)
    for attribute in attributes:
        attributes_dict[attribute.get_type()] = attribute

func _get_default_config() -> Variant:
    return {}

func _load_config(stream: Stream) -> Variant:
    return AdapterConfig.load_config(stream)

func _save_config(config: Variant, stream: Stream) -> void:
    AdapterConfig.save_config(config, stream)

func get_default_config() -> Variant:
    return _get_default_config()

func load_config(stream: Stream) -> Variant:
    return _load_config(stream)

func save_config(config: Variant, stream: Stream) -> void:
    return _save_config(config, stream)

func _can_be_replaced_by(building: Building, building_type: BuildingType) -> bool:
    return false

func can_be_replaced_by(building: Building, building_type: BuildingType) -> bool:
    return _can_be_replaced_by(building, building_type)

func _get_attribute(type: BuildingAttributeType) -> BuildingAttribute:
    return attributes_dict[type] if attributes_dict.has(type) else null

func get_attribute(type: BuildingAttributeType) -> BuildingAttribute:
    return _get_attribute(type)

func _get_rotatable() -> bool:
    return false

func get_rotatable() -> bool:
    return _get_rotatable()

func _get_default_building_category() -> BuildingCategory:
    return null
