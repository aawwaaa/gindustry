class_name ContentType
extends ResourceType

@export var order: int = 0
@export var icon: Texture2D = load("res://assets/asset-not-found.png")

@export var selector_panel: PackedScene

static var TYPE: ResourceTypeType
static var CONTENT: ContentType

var contents: Array[Content] = []

func _get_type() -> ResourceTypeType:
    return TYPE

