class_name BuildingType
extends EntityType

@export var icon: Texture2D = load("res://assets/asset-not-found.png")
@export var shadow: PackedScene

@export var category: BuildingCategory
@export var requirements: Array[TypedItemStack] = []

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

func _get_default_config() -> Variant:
    return null

func _load_config(stream: Stream) -> Variant:
    return null

func _save_config(config: Variant, stream: Stream) -> void:
    pass

func _can_be_replaced_by(building: Building, building_type: BuildingType) -> bool:
    return false
