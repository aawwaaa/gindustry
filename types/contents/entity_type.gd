class_name EntityType
extends Content

@export var entity_scene: PackedScene

@export var controllable: bool = false;

func create_entity(init: bool = true) -> Entity:
    var inst = entity_scene.instantiate();
    var entity = inst.get_entity();
    entity.entity_type = self;
    if init:
        entity.init_entity();
    return entity;

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "Entity")

func _get_content_type() -> String:
    return "entity"
