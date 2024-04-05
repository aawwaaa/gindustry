class_name UIPanelAdapter
extends EntityAdapter

const DEFAULT_NAME = "panel"

static var default_entity_info_panel_scene = load("res://ui/entity_info_panel/templates/default.tscn")

@export var inventory_panel_scene: PackedScene;
@export var entity_info_panel_scene: PackedScene;

@export_group("callbacks", "callback_")
@export var callback_init_inventory_panel: StringName = ""
@export var callback_init_entity_info_panel: StringName = ""

func create_inventory_panel() -> InventoryPanel:
    var panel = inventory_panel_scene.instantiate()
    panel.entity = entity_node
    panel.main_node = main_node
    if callback_init_inventory_panel != "":
        main_node.call(callback_init_inventory_panel, panel)
    panel.load_panel()
    return panel

func create_entity_info_panel() -> EntityInfoPanel:
    var panel = entity_info_panel_scene.instantiate()
    panel.entity = entity_node
    if callback_init_entity_info_panel != "":
        main_node.call(callback_init_entity_info_panel, panel)
    panel.load_panel()
    return panel

static func create_inventory_panel_for(entity: Entity) -> InventoryPanel:
    var adapter = entity.get_adapter(UIPanelAdapter.DEFAULT_NAME) as UIPanelAdapter
    if adapter and adapter.inventory_panel_scene: return adapter.create_inventory_panel()
    return null

static func create_entity_info_panel_for(entity: Entity) -> EntityInfoPanel:
    var adapter = entity.get_adapter(UIPanelAdapter.DEFAULT_NAME) as UIPanelAdapter
    if adapter and adapter.entity_info_panel_scene: return adapter.create_entity_info_panel()
    var panel = default_entity_info_panel_scene.instantiate()
    panel.entity = entity
    panel.load_panel()
    return panel
