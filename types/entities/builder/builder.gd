class_name Builder
extends Node2D

@export var entity: Entity
@export var builder_type: BuilderType:
    get: return entity.entity_type

var build_target_ref: int

func get_entity() -> Entity:
    return entity

func get_attribute(key: String) -> Variant:
    match key:
        "_": return null
    return null

func _on_entity_layer_changed(layer: int, from: int) -> void:
    var mask = get_entity().get_collision_mask( \
            builder_type.build_range_layer_begin, \
            builder_type.build_range_layer_end);
    $Area2D.collision_mask = mask
    $Area2D.collision_layer = mask
