class_name Recipe
extends Content

const RECIPE_TYPE = preload("res://contents/content_types/recipe.tres")

@export var consumers: Array[Consumer] = []
@export var providers: Array[Provider] = []

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "recipe")

func _get_content_type() -> ContentType:
    return RECIPE_TYPE

func get_consumers() -> Array[Consumer]:
    return consumers

func get_providers() -> Array[Provider]:
    return providers

func check_recipe(building: Building) -> bool:
    for consumer in consumers:
        if not consumer.check_recipe(building):
            return false
    for provider in providers:
        if not provider.check_recipe(building):
            return false
    return true
