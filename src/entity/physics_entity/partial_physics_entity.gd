class_name PartialPhysicsEntity
extends PhysicsEntity

func _get_physics_body_rid() -> RID:
    return get_parent_standalone_physics_entity().get_physics_body_rid()

func _on_transform_changed(source: Entity) -> void:
    super._on_transform_changed(source)

func _entity_init() -> void:
    super._entity_init()
    var parent = get_parent_standalone_physics_entity()
    if not parent: return
    parent.add_physics_child(self)

func _entity_deinit() -> void:
    var parent = get_parent_standalone_physics_entity()
    if not parent: return
    parent.remove_physics_child(self)
    super._entity_deinit()

