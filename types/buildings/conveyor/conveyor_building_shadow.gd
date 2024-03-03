class_name BuildingShadow_Conveyor
extends BuildingShadow

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
