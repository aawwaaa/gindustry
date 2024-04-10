class_name TileInfoPanel
extends VBoxContainer

@onready var floor_panel: VBoxContainer = %FloorPanel
@onready var floor_icon: TextureRect = %FloorIcon
@onready var floor_name: Label = %FloorName
@onready var floor_ores: VBoxContainer = %FloorOres
@onready var overlay_panel: VBoxContainer = %OverlayPanel
@onready var overlay_icon: TextureRect = %OverlayIcon
@onready var overlay_name: Label = %OverlayName
@onready var overlay_ores: VBoxContainer = %OverlayOres

func _process(delta: float) -> void:
    apply_data(Global.input_handler.get_focused_tile())

func reset_state() -> void:
    floor_panel.visible = false
    for child in floor_ores.get_children():
        child.queue_free()
    overlay_panel.visible = false
    for child in overlay_ores.get_children():
        child.queue_free()

func apply_data(tile: Tile) -> void:
    reset_state()
    if not tile: return
    # todo here
