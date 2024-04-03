class_name EntityInfoModule
extends HBoxContainer

var entity: Entity
var panel: EntityInfoPanel
var main_node: Node2D:
    get: return entity.main_node

func _load_module() -> void:
    pass

func load_module() -> void:
    _load_module()
