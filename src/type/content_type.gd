class_name ContentType
extends ResourceType

static var TYPE: ResourceTypeType

static var CONTENT: ContentType
static var ENTITY: ContentType
static var BLOCK: ContentType
static var ITEM: ContentType
static var FLUID: ContentType
static var ENERGY: ContentType
static var MESH_BLOCK: ContentType

@export var order: int = 0
@export var icon: Texture2D = load("res://assets/asset-not-found.png")

@export var selector_panel: PackedScene

var contents: Array[Content] = []

func _get_type() -> ResourceTypeType:
    return TYPE

