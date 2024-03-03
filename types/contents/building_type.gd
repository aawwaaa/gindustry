class_name BuildingType
extends EntityType

@export var icon: Texture2D = load("res://assets/asset-not-found.png")
@export var shadow: PackedScene

@export var category: BuildingCategory
@export var requirements: Array[PackedItemStack] = []

@export var attributes: Array[BuildingAttribute] = []
var attributes_dict: Dictionary = {}

var requirements_cache: Array[Item] = []

func get_requirements() -> Array[Item]:
    if requirements_cache.size() != 0: return requirements_cache
    var array: Array[Item] = []
    for item in requirements:
        array.append(item.get_item())
    requirements_cache = array
    return array

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "Building")

func _get_content_type() -> String:
    return "building"

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
    category.building_types.append(self)
    for attribute in attributes:
        attributes_dict[attribute.get_type()] = attribute

func _get_default_config() -> Variant:
    return null

func _load_config(stream: Stream) -> Variant:
    return null

func _save_config(config: Variant, stream: Stream) -> void:
    pass

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
