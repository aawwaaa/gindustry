class_name ContentCategory
extends ResourceType

static var TYPE: ResourceTypeType

static var RESOURCE: ContentCategory
static var TRANSPORTATION: ContentCategory
static var PRODUCTION: ContentCategory
static var MILITARY: ContentCategory
static var MESH: ContentCategory

static var MISC: ContentCategory

@export var order: int = 0
@export var icon: Texture2D = load("res://assets/asset-not-found.png")

var contents: Array[Content] = []

func _get_type() -> ResourceTypeType:
    return TYPE

func add_content(content: Content) -> void:
    contents.append(content)
