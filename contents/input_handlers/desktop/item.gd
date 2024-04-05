class_name DesktopInputHandler_Item
extends InputHandlerModule

var mouse_position: Vector2
var world_position: Vector2

var item_use_position: Vector2;
var item_use: ItemUse;

var enabled: bool = true:
    set(v): enabled = v; update_item_use()
var activate: bool = false;

func handle_input(event: InputEvent) -> void:
    handle_input_event(event) 

func handle_unhandled_input(event: InputEvent) -> void:
    handle_input_event(event, true) 

func handle_input_event(event: InputEvent, unhandled: bool = false) -> void:
    if event is InputEventMouse:
        mouse_position = event.position
        var trans = Game.camera_node.get_viewport_transform()
        world_position = trans.affine_inverse() * mouse_position
    if not entity: return
    item_use_position = world_position
    update_item_use()
    var inventory = entity.get_adapter(Inventory.DEFAULT_NAME)
    var item = inventory.get_slot(inventory.hand_slot)
    if unhandled and enabled:
        if item and Input.is_action_just_pressed("drop_an_item"): confirm_drop_item("one", world_position)
        elif item and Input.is_action_just_pressed("drop_half_item"): confirm_drop_item("half", world_position)
        elif item and Input.is_action_just_pressed("drop_all_item"): confirm_drop_item("all", world_position)
        elif item_use and Input.is_action_just_pressed("confirm_item_use"): confirm_item_use()
        elif Input.is_action_just_pressed("open_panel") \
                and (handler.get_interacting_target() in handler.interacting_entities \
                        or handler.get_interacting_target() in handler.interacting_adapters) :
            handler.interact_operate("open_panel", [world_position])
        elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            handler.interact_operate("clicked", [world_position])

func update_item_use() -> void:
    var inventory = entity.get_adapter(Inventory.DEFAULT_NAME)
    var item = inventory.get_slot(inventory.hand_slot)
    if item and not item.useable_no_await(entity, entity.world, item_use_position):
        item = null
    if not enabled: item = null
    activate = item != null
    if not item and item_use:
        item_use.queue_free()
        item_use = null
        return
    if not item: return
    if item_use and item_use.item != item:
        item_use.queue_free()
        item_use = null
    if not item_use:
        item_use = item.create_use(entity, entity.world)
        item_use.inventory = inventory
        item_use.slot = inventory.hand_slot
    item_use._set_position(item_use_position)

func confirm_item_use() -> void:
    if not item_use:
        return
    controller.operate_target(ControllerAdapter.TARGET_ADAPTER, ["inventory", "use_hand", entity.world, item_use_position])
    item_use.queue_free()
    item_use = null

func confirm_drop_item(type: String, pos: Vector2) -> void:
    var interacting = handler.get_interacting_target()
    if not interacting:
        controller.operate_target(ControllerAdapter.TARGET_ADAPTER, ["inventory", "drop_item_at", entity.world, pos, type])
        return
    handler.interact_operate("drop_item", [type, pos])

func accept_drop_item(target: Node2D, args: Array) -> void:
    var entity = target.get_entity()
    controller.operate_target(ControllerAdapter.TARGET_ADAPTER, ["inventory", "drop_item", entity, args[0]])

func access_target_ui(target: Node2D) -> void:
    controller.request_access_target(target)
    GameUI.instance.player_inventory.show()

func clear_access_target() -> void:
    controller.clear_access_target()

func access_and_operate(target: Node2D, operation: String, args: Array[Variant] = []) -> void:
    if not entity: return
    var current = entity.access_target
    controller.request_access_target.call_deferred(target)
    await entity.access_target_changed
    if not entity: return
    controller.operate_remote_target(operation, args)
