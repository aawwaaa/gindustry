class_name UIPanelAdapter
extends EntityAdapter

@export var panel_scene: PackedScene;

@export_group("callbacks", "callback_")
@export var callback_init_panel: StringName = ""

func create_panel() -> InventoryPanel:
    var panel = panel_scene.instantiate()
    panel.entity = entity_node
    panel.main_node = main_node
    if callback_init_panel != "": main_node.call(callback_init_panel, panel)
    return panel
