class_name DesktopInputHandler_Interact
extends InputHandlerModule

var mouse_position: Vector2

var enabled: bool = true:
    set(v): enabled = v;
var activate: bool = false;

func handle_input(event: InputEvent) -> bool:
    return handle_input_event(event) 

func handle_unhandled_input(event: InputEvent) -> bool:
    return handle_input_event(event, true) 

func handle_input_event(event: InputEvent, unhandled: bool = false) -> bool:
    if event is InputEventMouse:
        mouse_position = event.position
    if not entity: return false
    var inventory = entity.get_adapter(Inventory.I_DEFAULT_NAME)
    var item = inventory.get_slot(inventory.hand_slot)
    if unhandled and enabled:
        if Input.is_action_just_pressed("interact_direct_interact") \
                and (handler.get_interacting_target() in handler.interacting_entities \
                        or handler.get_interacting_target() in handler.interacting_adapters) :
            handler.interact_operate(InputInteracts.INTERACT_I_DIRECT_INTERACT, [world_pos])
            return true
        if Input.is_action_just_pressed("interact_click"):
            handler.interact_operate(InputInteracts.INTERACT_I_CLICK, [world_pos])
            return true
    return false

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
