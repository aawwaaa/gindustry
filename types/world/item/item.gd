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

func _apply_type(typed: TypedItemStack) -> void:
    amount = typed.amount

func _set_in_inventory(in_inventory: bool, inventory: Inventory) -> void:
    pass

func _is_same_item(another: Item) -> bool:
    return another.item_type == item_type

func _is_empty() -> bool:
    return amount <= 0

func _split_to(merge_amount: int, target: Item = null, override_max_stack: bool = false) -> Item:
    if target == null or not is_instance_valid(target): target = _copy_type()
    target._merge_from(self, override_max_stack, merge_amount)
    return target

func _merge_from(source: Item, override_max_stack: bool = false, merge_amount: int = source.amount) -> Item:
    if not _is_same_item(source):
        return source
    merge_amount = min(merge_amount, source.amount)
    var available = item_type.max_stack - amount
    var transfer = min(available, merge_amount) if not override_max_stack else merge_amount
    amount += transfer
    source.amount -= transfer
    if source._is_empty():
        source.queue_free()
        return null
    return source

func _useable_no_await(entity: Entity, world: World, target_position: Vector2) -> bool:
    if not item_type.useable: return false
    return true

func _useable(entity: Entity, world: World, target_position: Vector2) -> bool:
    if not _useable_no_await(entity, world, target_position): return false
    if not await entity.check_access_range(world, target_position):
        return false
    return true

func _create_use(entity: Entity, world: World) -> ItemUse:
    var use = item_type.use_scene.instantiate()
    use.world = world
    use.user = entity
    use.item = self
    world.add_temp_node(use)
    return use

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
   
