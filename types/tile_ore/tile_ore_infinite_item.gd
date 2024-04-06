class_name TileOre_InfiniteItem
extends TileOre

const TYPE = preload("res://contents/tile_ore_types/item.tres")

@export var item_stack: PackedItemStack

func _get_type() -> TileOreType:
    return TYPE

func _create_item(tile: Tile, ore_type: String) -> Item:
    return item_stack.create_item()

func create_item(tile: Tile, ore_type: String) -> Item:
    return _create_item(tile, ore_type)

