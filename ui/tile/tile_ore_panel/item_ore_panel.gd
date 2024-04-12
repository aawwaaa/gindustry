class_name TileOre_ItemOrePanel
extends HBoxContainer

static var scene: PackedScene = load("res://ui/tile/tile_ore_panel/item_ore_panel.tscn")

@onready var item_container: Control = %ItemContainer
@onready var item_name: Label = %ItemName
@onready var item_amount: Label = %ItemAmount
@onready var ore_amount: Label = %OreAmount

var stack: PackedItemStack
var ore: TileOre
var tile: Tile
var type: String

func apply_data(stack: PackedItemStack) -> void:
    for child in item_container.get_children():
        child.queue_free()
    
    var display = stack.get_item().create_display()
    item_container.add_child(display)
    item_name.text = stack.get_item().get_localized_name()
    item_amount.text = str(stack.get_item().amount)

func apply_amount(amount: int = -1) -> void:
    ore_amount.text = str(amount)
    ore_amount.visible = amount != -1

func _ready() -> void:
    apply_data(stack)
    _process(0)

func _process(delta: float) -> void:
    var amount = ore.get_data(tile, type) if ore is TileOreWithData \
            else -1
    apply_amount(amount)
