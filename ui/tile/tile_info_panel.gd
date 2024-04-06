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

func reset_state() -> void:
    pass

func apply_data(tile: Tile) -> void:
    pass
