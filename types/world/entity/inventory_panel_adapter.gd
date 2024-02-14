class_name InventoryPanelAdapter
extends Node

@export var entity: Entity;
@export var panel_scene: PackedScene;

func create_panel() -> InventoryPanel:
    var panel = panel_scene.instantiate()
    panel.entity = entity
    panel.main_node = entity.main_node
    return panel
