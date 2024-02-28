class_name InventoryPanelAdapter
extends EntityAdapter

@export var panel_scene: PackedScene;

func create_panel() -> InventoryPanel:
    var panel = panel_scene.instantiate()
    panel.entity = entity_node
    panel.main_node = main_node
    return panel
