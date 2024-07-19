class_name Vars_Contents
extends Vars.Vars_Object

signal content_registed(content: Content)

var contents: Array[Content]
var contents_mapping: Dictionary # String -> Content
var contents_mapping_based_type: Dictionary # ContentType -> String -> Content
var contents_mapping_based_category: Dictionary # ContentCategory -> ContentType -> String -> Content

func register_content(content: Content) -> Content:
    content.mod = Vars.mods.current_loading_mod
    content._data()
    Vars_Objects.add_object_type(content)
    contents.append(content)
    content.mod.contents.append(content)
    var full_id = content.get_full_id()
    contents_mapping[full_id] = content
    if not contents_mapping_based_type.has(content.content_type):
        contents_mapping_based_type[content.content_type] = {}
    if not contents_mapping_based_category.has(content.content_category):
        contents_mapping_based_category[content.content_category] = {}
    if not contents_mapping_based_category[content.content_category].has(content.content_type):
        contents_mapping_based_category[content.content_category][content.content_type] = {}
    contents_mapping_based_type[content.content_type][full_id] = content
    contents_mapping_based_category[content.content_category][content.content_type][full_id] = content
    content._content_registed()
    content._assign()
    return content

func get_contents(type: ContentType) -> Array[Content]:
    return contents_mapping_based_type[type].values()

func get_contents_by_category(category: ContentCategory, type: ContentType) -> Array[Content]:
    return contents_mapping_based_category[category][type].values()

func get_content_by_full_id(full_id: String) -> Content:
    return contents_mapping[full_id] if contents_mapping.has(full_id) else null

func get_content_by_index(index: int) -> Content:
    return Vars.objects.get_object_type_by_index(index)
