class_name ContentCategory
extends ResourceType

static var TYPE: ResourceTypeType
static var UNCATEGORIED: ContentCategory

@export var order: int = 0
@export var icon: Texture2D = load("res://assets/asset-not-found.png")

var contents: Array[Content] = []

func _get_type() -> ResourceTypeType:
    return TYPE

func add_content(content: Content) -> void:
    contents.append(content)
