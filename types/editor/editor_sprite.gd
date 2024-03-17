@tool
class_name EditorSprite
extends Sprite2D

func _ready() -> void:
    if not Engine.is_editor_hint():
        queue_free()

