class_name BuilderAdapter
extends EntityAdapter

@export var builders: Array[Builder] = [];

func _enter_tree() -> void:
    entity_node.child_entities_main_node.append_array(builders);
