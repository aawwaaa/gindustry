class_name Item
extends Node2D

const INF_AMOUNT = 2 << 32 - 1

var item_type: ItemType
var amount: int = 0

func _ready() -> void:
    %Icon.texture = item_type.texture

func _copy_type() -> Item:
    var new_item = item_type.create_item()
    return new_item

func copy_type() -> Item:
    return _copy_type()

func _apply_type(typed: TypedItem) -> void:
    pass

func _apply_stack(stack: PackedItemStack) -> void:
    amount = stack.amount

func apply_type(type: TypedItem) -> void:
    _apply_type(type)

func apply_stack(stack: PackedItemStack) -> void:
    _apply_stack(stack)

func _set_in_inventory(in_inventory: bool, inventory: Inventory) -> void:
    pass

func _is_same_item(another: Item) -> bool:
    return another.item_type == item_type

func _is_empty() -> bool:
    return amount <= 0

func is_same_item(another: Item) -> bool:
    return _is_same_item(another)

func is_empty() -> bool:
    return _is_empty()

func _get_max_stack_amount() -> int:
    return item_type.max_stack

func get_max_stack_amount() -> int:
    return _get_max_stack_amount()

func _get_available_merge_amount(type: Item) -> int:
    return get_max_stack_amount() - amount

func get_available_merge_amount(type: Item) -> int:
    return _get_available_merge_amount(type)

func _get_merge_amount(source: Item, override_max_stack: bool, merge_amount: int) -> int:
    merge_amount = min(merge_amount, source.amount)
    var available = get_available_merge_amount(source)
    var transfer = min(available, merge_amount) if not override_max_stack else merge_amount
    return transfer 

func get_merge_amount(source: Item, override_max_stack: bool = false, merge_amount: int = source.amount) -> int:
    if not is_same_item(source):
        return 0
    return _get_merge_amount(source, override_max_stack, merge_amount)

func _split_to(merge_amount: int, target: Item, override_max_stack: bool) -> Item:
    target.merge_from(self, override_max_stack, merge_amount)
    return target

func split_to(merge_amount: int, target: Item = null, override_max_stack: bool = false) -> Item:
    if target == null or not is_instance_valid(target): target = copy_type()
    return _split_to(merge_amount, target, override_max_stack)

func _merge_from(source: Item, override_max_stack: bool, merge_amount: int) -> Item:
    var transfer = get_merge_amount(source, override_max_stack, merge_amount)
    amount += transfer
    source.amount -= transfer
    return source

func merge_from(source: Item, override_max_stack: bool = false, merge_amount: int = source.amount) -> Item:
    if not is_same_item(source):
        return source
    source = _merge_from(source, override_max_stack, merge_amount)
    if source.is_empty():
        source.queue_free()
        return null
    return source

func _useable_no_await(entity: Entity, world: World, target_position: Vector2) -> bool:
    return true

func useable_no_await(entity: Entity, world: World, target_position: Vector2) -> bool:
    if not item_type.useable: return false
    return _useable_no_await(entity, world, target_position)

func _useable(entity: Entity, world: World, target_position: Vector2) -> bool:
    if not await entity.check_access_range(world, target_position):
        return false
    return true

func useable(entity: Entity, world: World, target_position: Vector2) -> bool:
    if not useable_no_await(entity, world, target_position): return false
    return await _useable(entity, world, target_position)

func _create_use(entity: Entity, world: World) -> ItemUse:
    var use = item_type.use_scene.instantiate()
    use.world = world
    use.user = entity
    use.item = self
    world.add_temp_node(use)
    return use

func create_use(entity: Entity, world: World) -> ItemUse:
    return _create_use(entity, world)

func _get_cost() -> float:
    return item_type.get_cost() * amount

func _get_amount(cost: float) -> int:
    return floori(cost / item_type.get_cost())

func get_cost() -> float:
    return _get_cost()

func get_amount_by_cost(cost: float) -> int:
    return _get_amount(cost)

static func load_from(stream: Stream) -> Item:
    var data_item_type = Contents.get_content_by_index(stream.get_32()) as ItemType;
    var item = data_item_type.create_item();
    item.load_data(stream);
    return item;

func save_to(stream: Stream) -> void:
    stream.store_32(item_type.index);
    save_data(stream);

const current_data_version = 0;

func load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return
    amount = stream.get_32();

func save_data(stream: Stream) -> void:
    stream.store_16(current_data_version);
    # version 0
    stream.store_32(amount)
   
