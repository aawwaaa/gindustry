class_name BuildingShadow_ConveyorJunction
extends BuildingShadow

func _ready() -> void:
    super._ready()
    var sprite: Sprite2D = display_sprite
    sprite.texture = building_type.texture_texture
    sprite.z_index = building_type.texture_z_index
    for polygon in display_polygons.get_children():
        polygon.texture = building_type.texture_polygon_texture
        polygon.texture_offset = building_type.texture_polygon_texture_offset


