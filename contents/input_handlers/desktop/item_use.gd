class_name DesktopInputHandler_ItemUse
extends InputHandlerModule

var item_use_position: Vector2;
var item_use: ItemUse;

var enabled: bool = true:
    set(v): enabled = v; update_item_use()
var activate: bool = false;

func _handle_input(event: InputEvent) -> void:
    if event is InputEventMouse: handle_input_event_mouse(event) 

func handle_input_event_mouse(event: InputEventMouse) -> void:
    var pos = event.position
    var trans = Game.camera_node.get_viewport_transform()
    var world_pos = trans.affine_inverse() * pos
    if entity: handle_item_use_mouse(world_pos)

func handle_item_use_mouse(world_pos: Vector2) -> void:
    item_use_position = world_pos
    if Input.is_action_just_pressed("item_use_confirm"):
        confirm_item_use()

func update_item_use() -> void:
    var inventory = entity.get_adapter("inventory")
    var item = inventory.get_slot(inventory.hand_slot)
    if item and not item._useable_no_await(entity, entity.world, item_use_position):
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
        item_use = item._create_use(entity, entity.world)
        item_use.inventory = inventory
        item_use.slot = inventory.hand_slot
    item_use._set_position(item_use_position)

func confirm_item_use() -> void:
    if not item_use:
        return
    controller.operate_target("inventory", ["use_hand", entity.world, item_use_position])
    item_use.queue_free()
    item_use = null

