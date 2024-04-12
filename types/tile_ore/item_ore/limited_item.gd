class_name TileOre_LimitedItem
extends TileOreWithData

const TYPE = preload("res://contents/tile_ore_types/item.tres")

@export var item_stack: PackedItemStack
@export var default_amount: int

func _get_type() -> TileOreType:
    return TYPE

func _create_item(tile: Tile, ore_type: String) -> Item:
    var amount = get_data(tile, ore_type)
    if amount <= 0: return null
    var item = item_stack.create_item()
    set_data(tile, ore_type, amount - 1)
    if get_data(tile, ore_type) <= 0: remove_tile_ore(tile, ore_type)
    return item

func create_item(tile: Tile, ore_type: String) -> Item:
    return _create_item(tile, ore_type)

func _init_ore_data(_tile: Tile, ore_type: String) -> Variant:
    return default_amount

func _has_panel(tile: Tile, ore_type: String) -> bool:
    return true

func _create_panel(tile: Tile, ore_type: String) -> Control:
    var panel = TileOre_ItemOrePanel.scene.instantiate() as TileOre_ItemOrePanel
    panel.stack = item_stack
    panel.ore = self
    panel.tile = tile
    panel.type = ore_type
    return panel

func _load_data(tile: Tile, ore_type: String, stream: Stream) -> void:
    set_data(tile, ore_type, stream.get_32())

func _save_data(tile: Tile, ore_type: String, stream: Stream) -> void:
    stream.store_32(get_data(tile, ore_type))
