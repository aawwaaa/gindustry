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

var last_focused_tile: Tile
var last_focused_tile_pos: Vector2i
var last_focused_tile_world: int

func _process(delta: float) -> void:
    if not Global.input_handler: return
    var tile = Global.input_handler.get_focused_tile()
    if tile == last_focused_tile \
            and (not tile or tile.tile_pos == last_focused_tile_pos \
                    and tile.world.world_id == last_focused_tile_world
            ): return
    last_focused_tile = tile
    last_focused_tile_pos = tile.tile_pos if tile else Vector2.ZERO
    last_focused_tile_world = tile.world.world_id if tile else 0
    apply_data(last_focused_tile)

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
    if tile.floor_type and tile.floor_type.should_show_panel(tile):
        floor_panel.visible = true
        floor_icon.texture = tile.floor_type.get_icon()
        floor_name.text = tile.floor_type.get_localized_name()
        tile.floor_type.add_panels_to(tile, floor_ores)
    else:
        floor_panel.visible = false

    if tile.overlay_type and tile.overlay_type.should_show_panel(tile):
        overlay_panel.visible = true
        overlay_icon.texture = tile.overlay_type.get_icon()
        overlay_name.text = tile.overlay_type.get_localized_name()
        tile.overlay_type.add_panels_to(tile, overlay_ores)
    else:
        overlay_panel.visible = false

