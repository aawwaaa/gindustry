class_name Content
extends ObjectType

var content_type: ContentType
var content_category: ContentCategory
var content_tags: Array[ContentTag] = []

func _get_full_id() -> String:
    return get_full_id_default(content_type.name)

func get_tr_name() -> String:
    return full_id

func _content_registed() -> void:
    content_type.contents.append(self)
    content_category.add_content(self)
    for tag in content_tags:
        tag.add_content(self)

func _data() -> void:
    content_type = ContentType.CONTENT
    content_category = ContentCategory.UNCATEGORIED

func _assign() -> void:
    pass

## Be call when in stage of load contents automatically
func _load() -> void:
    pass

func _load_assets() -> void:
    pass
func _load_headless() -> void:
    pass
