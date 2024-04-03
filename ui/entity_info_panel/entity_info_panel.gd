class_name EntityInfoPanel
extends PanelContainer

@export var modules: Array[EntityInfoModule]

var entity: Entity
var main_node: Node2D:
    get: return entity.main_node

func load_panel() -> void:
    for module in modules:
        module.entity = entity
        module.panel = self
        module.load_module()
