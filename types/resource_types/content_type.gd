class_name ContentType
extends ResourceType

const TYPE = preload("res://contents/resource_types/content_type.tres")

var contents: Array[Content] = []
var contents_indexed: Dictionary = {}

func _get_type() -> ResourceType:
    return TYPE

func register_content(content: Content) -> void:
    contents.append(content)
    contents_indexed[content.id] = content

