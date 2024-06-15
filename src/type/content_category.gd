class_name ContentCategory
extends ResourceType

const TYPE = preload("res://contents/resource_types/content_category.tres")
const UNCATEGORIZED = preload("res://contents/content_categories/uncategorized.tres")

@export var order: int = 0
@export var icon: Texture2D = load("res://assets/asset-not-found.png")

var contents: Array[Content] = []

func _get_type() -> ResourceTypeType:
    return TYPE

func add_content(content: Content) -> void:
    contents.append(content)
