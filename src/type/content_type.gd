class_name ContentType
extends ResourceType

const CONTENT = preload("res://contents/content_types/content.tres")

static var TYPE: ResourceTypeType
static func _static_init() -> void:
    TYPE = ResourceTypeType.new()
    TYPE.name = "content_type"

@export var order: int = 0
@export var icon: Texture2D = load("res://assets/asset-not-found.png")

static var PLACEHOLDER = ContentType.new()

var contents: Array[Content] = []

func _get_type() -> ResourceTypeType:
    return TYPE

