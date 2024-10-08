extends RigidBody2D

@export var entity: Entity

func get_entity() -> Entity:
    return entity;

func _on_entity_layer_changed(_layer: int, _from: int) -> void:
    z_index = get_entity().get_z_index(0)
    var mask = get_entity().get_collision_mask(0, 0);
    collision_layer = mask;
    collision_mask = mask;
