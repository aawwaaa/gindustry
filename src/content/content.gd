class_name Content
extends ObjectType

var content_type: ContentType = ContentType.CONTENT
var content_category: ContentCategory = ContentCategory.UNCATEGORIZED

func _get_full_id() -> String:
    return get_full_id_default(content_type.name)

func get_tr_name() -> String:
    return full_id

func _content_registed() -> void:
    content_type.contents.append(self)
    content_category.add_content(self)
