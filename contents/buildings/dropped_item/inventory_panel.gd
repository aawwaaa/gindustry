extends InventoryPanel

@export var interface: UIInventoryInterface

func _ready() -> void:
    interface.load_inventory()
