class_name BuilderAdapter
extends EntityAdapter

@export var builder_containers: Array[EntityContainer] = [];
@export var builder_type: BuilderType;

func _enter_tree() -> void:
    for container in builder_containers:
        container.entity_type = builder_type
    entity_node.child_entities_main_node.append_array(builder_containers);
