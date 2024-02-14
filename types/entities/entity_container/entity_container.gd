class_name EntityContainer
extends Node2D

@export var entity_type: EntityType
var entity: Entity

func get_entity() -> Entity:
    if not entity:
        var entity_node = entity_type.create_entity(false)
        add_child(entity_node.main_node)
        entity = entity_node
    return entity
