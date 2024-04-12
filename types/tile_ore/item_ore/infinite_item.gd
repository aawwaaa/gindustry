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

func _has_panel(tile: Tile, ore_type: String) -> bool:
    return true

func _create_panel(tile: Tile, ore_type: String) -> Control:
    var panel = TileOre_ItemOrePanel.scene.instantiate() as TileOre_ItemOrePanel
    panel.stack = item_stack
    panel.ore = self
    panel.tile = tile
    panel.type = ore_type
    return panel
