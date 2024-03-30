class_name PlayerInventory
extends Window

@export var default_inventory_panel: PackedScene;
var default_inventory_panel_inst: PlayerInventoryPanel;

func _ready() -> void:
    default_inventory_panel_inst = default_inventory_panel.instantiate()
    Global.input_handler_changed.connect(_on_input_handler_changed)

func _on_close_requested() -> void:
    hide()
    Global.input_handler.call_input_processor("item", "clear_access_target")

func _on_input_handler_changed(handler: InputHandler, from: InputHandler) -> void:
    Utils.signal_dynamic_connect(handler, from, "controller_target_entity_changed", \
            _on_input_handler_controller_target_entity_changed)
    _on_input_handler_controller_target_entity_changed(handler.entity, from.entity if from else null);

func _on_input_handler_controller_target_entity_changed(entity: Entity, from: Entity) -> void:
    Utils.signal_dynamic_connect(entity, from, "access_target_changed", \
            _on_controller_target_access_target_changed)
    %InventoryInterface.entity = entity
    if entity and entity.has_adapter("inventory"):
        %InventoryInterface.adapter = entity.get_adapter("inventory")
    else:
        %InventoryInterface.adapter = null
    %InventoryInterface.load_inventory()

    default_inventory_panel_inst.entity = entity

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        Global.input_handler._input(event)

func toggle_inventory() -> void:
    if not visible or not default_inventory_panel_inst.is_inside_tree():
        load_info(null)
        show()
    else:
        hide()
        Global.input_handler.call_input_processor("item", "clear_access_target")

func _on_controller_target_access_target_changed(target: Node2D, from: Node2D) -> void:
    load_info(target.get_entity() if target else null)

func load_info(access_target: Entity) -> void:
    for child in %Info.get_children():
        %Info.remove_child(child)
        if child == default_inventory_panel_inst:
            child.request_operation.disconnect(_on_panel_request_operation)
            child.request_remote_operation.disconnect(_on_panel_request_remote_operation)
            continue
        child.queue_free()
    if access_target == null or not access_target.has_adapter("panel"):
        %Info.add_child(default_inventory_panel_inst)
    else:
        var panel = access_target.get_adapter("panel")
        %Info.add_child(panel.create_panel())

    for child in %Info.get_children():
        child.request_operation.connect(_on_panel_request_operation)
        child.request_remote_operation.connect(_on_panel_request_remote_operation)

func _on_game_ui_ui_hidden() -> void:
    %InventoryInterface.adapter = null
    %InventoryInterface.load_inventory()
    
    load_info(null)
    hide()

    default_inventory_panel_inst._on_game_ui_ui_hidden()

func _on_panel_request_operation(operation: String, args: Array[Variant]) -> void:
    Game.current_player.get_controller().operate_target(operation, args)

func _on_panel_request_remote_operation(operation: String, args: Array[Variant]) -> void:
    Game.current_player.get_controller().operate_remote_target(operation, args)

