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

func get_entity() -> Entity:
    return entity

func _on_entity_layer_changed(layer: int, from: int) -> void:
    if not shadow: return
    shadow.layer = layer

func calcuate_missing_items() -> void:
    for item in building_type.get_requirements():
        var amount = 0
        for fitem in filled_items:
            if item._is_same_item(fitem):
                amount = fitem.amount
                break
        amount = item.amount - amount
        var found = false
        var removes: Array[Item] = []
        for mitem in missing_items:
            if item._is_same_item(mitem):
                mitem.amount = amount
                found = true
                if amount == 0: removes.append(mitem)
                break
        for remove in removes:
            missing_items.erase(remove)
            remove.queue_free()
        if found or amount == 0: continue
        var missing_item = item._copy_type()
        missing_item.amount = amount
        missing_items.append(missing_item)

func calcuate_building_progress(do_operate = true) -> void:
    var total_cost = 0
    for item in building_type.get_requirements():
        total_cost += item._get_cost()
    var current_cost = 0
    for fitem in filled_items:
        current_cost += fitem._get_cost()
        shadow.build_progress = current_cost / total_cost
    if not do_operate: return
    if current_cost >= total_cost:
        shadow.finish_build()
        return
    if current_cost == 0:
        destroy();

func fill_item(item: Item) -> Item:
    var missing_amount = 0
    for mitem in missing_items:
        if mitem._is_same_item(item):
            missing_amount = mitem.amount
            break
    var found = false
    for fitem in filled_items:
        if fitem._is_same_item(item):
            item._split_to(missing_amount, fitem, true)
            found = true
            break
    if not found:
        filled_items.append(item._split_to(missing_amount, null, true))
    calcuate_missing_items()
    calcuate_building_progress()
    if shadow.build_progress == 1:
        entity.world.get_tile_or_null(entity.tile_pos).set_building(building_type, rotation, building_config)
    return item

func remove_item(total_cost: float) -> Dictionary:
    var removed_items: Array[Item] = []
    var emptys: Array[Item] = []
    for item in filled_items:
        var removeable_cost = min(item._get_cost(), total_cost)
        var amount = item._get_amount(removeable_cost)
        var splited = item._split_to(amount, null, true)
        total_cost -= splited._get_cost()
        removed_items.append(splited)
        if item._is_empty(): emptys.append(item)
        if total_cost <= 0: break
    for item in emptys: filled_items.erase(item)
    calcuate_missing_items()
    calcuate_building_progress()
    if shadow.build_progress == 0:
        entity.world.get_tile_or_null(entity.tile_pos).clear_building()
    return {"removed_items": removed_items, "costs": total_cost}

func _ready() -> void:
    shadow = building_type.create_shadow()
    shadow.world = entity.world
    shadow.pos = entity.tile_pos
    shadow.rot = rotation
    shadow.building_config = building_config
    _on_entity_layer_changed(entity.layer, -1)
    add_child(shadow)
    shadow.build_progress = 0
    calcuate_missing_items()
    calcuate_building_progress(false)
    if should_place: place()
    if should_destroy: destroy()

func _exit_tree() -> void:
    for item in filled_items:
        item.queue_free()
    for item in missing_items:
        item.queue_free()

func place() -> void:
    if not shadow: 
        should_place = true
        return
    should_place = false
    for pos in shadow.tiles:
        var tile = entity.world.get_tile_or_null(entity.tile_pos + pos)
        if not tile: continue
        tile.building_ref = entity.entity_id 

func destroy() -> void:
    if not shadow:
        should_destroy = true
        return
    should_destroy = false
    for pos in shadow.tiles:
        var tile = entity.world.get_tile_or_null(entity.tile_pos + pos)
        if not tile: continue
        tile.building_ref = 0
    entity.remove()

const current_data_version: int = 0

func _on_entity_on_load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return;
    building_type = Contents.get_content_by_index(stream.get_64()) as BuildingType
    building_config = building_type._load_config(stream)
    filled_items = []
    for _1 in range(stream.get_16()):
        var item = Item.new()
        item.load_data(stream)
        filled_items.append(item)
    calcuate_missing_items()
    calcuate_building_progress(false)

func _on_entity_on_save_data(stream: Stream) -> void:
    stream.store_16(current_data_version);
    # version 0
    stream.store_64(building_type.index)
    building_type._save_config(building_config, stream)
    stream.store_16(filled_items.size())
    for item in filled_items:
        item.save_data(stream)
