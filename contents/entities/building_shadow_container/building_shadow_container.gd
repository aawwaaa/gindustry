class_name BuildingShadowContainer
extends Node2D

@export var entity: Entity

var building_type: BuildingType
var building_config: Variant
var shadow: BuildingShadow

var should_place: bool = false
var should_destroy: bool = false

var filled_items: Array[Item] = []
var missing_items: Array[Item] = []

var pos: Vector2i
var rot: int

func get_entity() -> Entity:
    return entity

func _on_entity_layer_changed(layer: int, from: int) -> void:
    if not shadow: return
    shadow.layer = layer

func calcuate_missing_items() -> void:
    for item in building_type.get_requirements():
        var amount = 0
        for fitem in filled_items:
            if item.is_same_item(fitem):
                amount = fitem.amount
                break
        amount = item.amount - amount
        var found = false
        var removes: Array[Item] = []
        for mitem in missing_items:
            if item.is_same_item(mitem):
                mitem.amount = amount
                found = true
                if amount == 0: removes.append(mitem)
                break
        for remove in removes:
            missing_items.erase(remove)
        if found or amount == 0: continue
        var missing_item = item.copy_type()
        missing_item.amount = amount
        missing_items.append(missing_item)

func calcuate_building_progress() -> void:
    var total_cost = 0
    for item in building_type.get_requirements():
        total_cost += item.get_cost()
    var current_cost = 0
    for fitem in filled_items:
        current_cost += fitem.get_cost()
    if total_cost == 0: shadow.build_progress = 1
    else: shadow.build_progress = current_cost / total_cost

func fill_item(item: Item) -> Item:
    var missing_amount = 0
    for mitem in missing_items:
        if mitem.is_same_item(item):
            missing_amount = mitem.amount
            break
    var found = false
    for fitem in filled_items:
        if fitem.is_same_item(item):
            item.split_to(missing_amount, fitem, true)
            found = true
            break
    if not found and item:
        filled_items.append(item.split_to(missing_amount, null, true))
    calcuate_missing_items()
    calcuate_building_progress()
    if shadow.build_progress == 1:
        entity.world.get_tile_or_null(pos) \
                .set_building(building_type, rot, building_config)

    return item

func remove_item(total_cost: float) -> Dictionary:
    var removed_items: Array[Item] = []
    var emptys: Array[Item] = []
    for item in filled_items:
        var removeable_cost = min(item.get_cost(), total_cost)
        var amount = item.get_amount_by_cost(removeable_cost)
        if amount <= 0: continue
        var splited = item.split_to(amount, null, true)
        total_cost -= splited.get_cost()
        removed_items.append(splited)
        if item.is_empty(): emptys.append(item)
        if total_cost <= 0: break
    for item in emptys: filled_items.erase(item)
    if not removed_items.is_empty():
        calcuate_missing_items()
        calcuate_building_progress()
    if shadow.build_progress == 0 or filled_items.is_empty():
        entity.world.get_tile_or_null(entity.tile_pos).clear_building()
    return {"removed_items": removed_items, "costs": total_cost}

func handle_destroy() -> void:
    pass

func _ready() -> void:
    position = Tile.to_world_pos(pos)
    rotation = Tile.to_entity_rot(rot)
    shadow = building_type.create_shadow()
    shadow.world = entity.world
    shadow.pos = pos
    shadow.building_config = building_config
    _on_entity_layer_changed(entity.layer, -1)
    add_child(shadow)
    shadow.entity = entity
    shadow.rot = rot
    shadow.build_progress = 0
    shadow.input_mouse_entered.connect(entity._on_collision_object_2d_mouse_entered)
    shadow.input_mouse_exited.connect(entity._on_collision_object_2d_mouse_exited)
    calcuate_missing_items()
    calcuate_building_progress()
    if should_place: place()
    if should_destroy: destroy()

func place() -> void:
    if not shadow: 
        should_place = true
        return
    should_place = false
    shadow.place(false, entity.entity_id)
    
func destroy() -> void:
    if not shadow:
        should_destroy = true
        return
    should_destroy = false
    shadow.destroy(false, entity.entity_id)

const current_data_version: int = 0

func _on_entity_on_load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return;
    building_type = Contents.get_content_by_index(stream.get_64()) as BuildingType
    pos = stream.get_var()
    rot = stream.get_8()
    building_config = building_type.load_config(stream)
    filled_items = []
    for _1 in range(stream.get_16()):
        var item = Item.load_from(stream)
        filled_items.append(item)

func _on_entity_on_save_data(stream: Stream) -> void:
    stream.store_16(current_data_version);
    # version 0
    stream.store_64(building_type.index)
    stream.store_var(pos, true)
    stream.store_8(rot)
    building_type.save_config(building_config, stream)
    stream.store_16(filled_items.size())
    for item in filled_items:
        item.save_to(stream)

func _on_entity_input_operation(operation: String, args: Array) -> void:
    if not operation == "continue_build": return
    Global.input_handler.call_input_processor("build", "continue_build", [self])

