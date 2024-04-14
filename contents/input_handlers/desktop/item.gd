class_name DesktopInputHandler_Item
extends InputHandlerModule

var mouse_position: Vector2

var item_use_position: Vector2;
var item_use: ItemUse;

var enabled: bool = true:
    set(v): enabled = v; update_item_use()
var activate: bool = false;

func handle_input(event: InputEvent) -> bool:
    return handle_input_event(event) 

func handle_unhandled_input(event: InputEvent) -> bool:
    return handle_input_event(event, true) 

func handle_input_event(event: InputEvent, unhandled: bool = false) -> bool:
    if event is InputEventMouse:
        mouse_position = event.position
    if not entity: return false
    item_use_position = world_pos
    update_item_use()
    var inventory = entity.get_adapter(Inventory.I_DEFAULT_NAME)
    var item = inventory.get_slot(inventory.hand_slot)
    if unhandled and enabled:
        if item and Input.is_action_just_pressed("item_drop_an_item"): confirm_drop_item("one", world_pos)
        elif item and Input.is_action_just_pressed("item_drop_half_item"): confirm_drop_item("half", world_pos)
        elif item and Input.is_action_just_pressed("item_drop_all_item"): confirm_drop_item("all", world_pos)
        elif item_use and Input.is_action_just_pressed("item_confirm_item_use"): confirm_item_use()
        else: return false
        return true
    return false

func update_item_use() -> void:
    var inventory = entity.get_adapter(Inventory.I_DEFAULT_NAME)
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
    controller.operate_target(ControllerAdapter.TARGET_ADAPTER, [Inventory.I_DEFAULT_NAME, "use_hand", entity.world, item_use_position])
    item_use.queue_free()
    item_use = null

func confirm_drop_item(type: String, pos: Vector2) -> void:
    var interacting = handler.get_interacting_target()
    if not interacting:
        controller.operate_target(ControllerAdapter.TARGET_ADAPTER, [Inventory.I_DEFAULT_NAME, "drop_item_at", entity.world, pos, type])
        return
    handler.interact_operate(InputInteracts.ITEM_I_DROP_ITEM, [type, pos])

func accept_drop_item(target: Node2D, args: Array) -> void:
    var entity = target.get_entity()
    controller.operate_target(ControllerAdapter.TARGET_ADAPTER, [Inventory.I_DEFAULT_NAME, "drop_item", entity, args[0]])
