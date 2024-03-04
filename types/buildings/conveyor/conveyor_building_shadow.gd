class_name BuildingShadow_Conveyor
extends BuildingShadow

var display_direction: int = Building_Conveyor.DisplayDirectons.left:
    set = set_display_direction

func get_animation_speed() -> float:
    return building_type.animation_speed if building_type else 8

func _process(delta: float) -> void:
    var sprite: Sprite2D = display_sprite
    if not full_build:
        sprite.frame = 0
        return
    var frames = sprite.hframes * sprite.vframes
    var duration = 1 / get_animation_speed()
    var current_frame = floori(Time.get_unix_time_from_system() / duration) % frames
    sprite.frame = current_frame

func _ready() -> void:
    super._ready()
    var sprite: Sprite2D = display_sprite
    sprite.hframes = building_type.hframes
    sprite.vframes = building_type.vframes
    set_display_direction(display_direction)
    for polygon in display_polygons.get_children():
        polygon.texture = building_type.texture_polygon_texture
        polygon.texture_offset = building_type.texture_polygon_texture_offset

func set_display_direction(v: int) -> void:
    var sprite: Sprite2D = display_sprite
    display_direction = v
    var left = Building_Conveyor.DisplayDirectons.left
    var up = Building_Conveyor.DisplayDirectons.up
    var down = Building_Conveyor.DisplayDirectons.down
    var left_up = left | up
    var left_down = left | down
    var left_up_down = left | up | down
    var up_down = up | down
    match display_direction:
        left:
            sprite.texture = building_type.texture_left
        left_up:
            sprite.texture = building_type.texture_left_up
        left_down:
            sprite.texture = building_type.texture_left_down
        left_up_down:
            sprite.texture = building_type.texture_left_up_down
        up:
            sprite.texture = building_type.texture_up
        down:
            sprite.texture = building_type.texture_down
        up_down:
            sprite.texture = building_type.texture_up_down
        _:
            sprite.texture = building_type.texture_left

