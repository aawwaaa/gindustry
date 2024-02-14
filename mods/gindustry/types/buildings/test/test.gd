extends Node2D

@export var entity: Building

func get_entity() -> Building:
    return entity

func get_attribute(key: String) -> Variant:
    match key:
        "_": return null
    return null
