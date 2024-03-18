extends Node

signal content_registed(content: Content)

@onready var log_source = Log.register_log_source("contents")

var contents: Array[Content] = []
var contents_indexed = {}
var contents_type_indexed = {}

var contents_mapping = {}
var contents_mapping_index = 1;

var contents_wait = {}

var current_loading_mod: Mod = null;

func register_content(content: Content) -> void:
    content.apply_mod(current_loading_mod);
    log_source.debug("Load content: " + content.full_id + " " + content.get_content_type().name)
    contents.append(content);
    contents_indexed[content.full_id] = content;
    var type = content.get_content_type();
    if not contents_type_indexed.has(type):
        contents_type_indexed[type] = []
    contents_type_indexed[type].append(content)
    type.register_content(content)
    content._content_registed();
    if contents_wait.has(content.full_id):
        for callback in contents_wait[content.full_id]:
            callback.call(content);
        contents_wait.erase(content.full_id)
    content_registed.emit(content)

func wait_for_content(full_id: String, callback: Callable) -> void:
    if not contents_wait.has(full_id):
        contents_wait[full_id] = []
    contents_wait[full_id].append(callback)

func get_content_by_id(id: String) -> Content:
    return contents_indexed[id] if contents_indexed.has(id) else null

func get_content_by_index(index: int) -> Content:
    return contents_mapping[index] if contents_mapping.has(index) else null

func init_contents_mapping() -> void:
    contents_mapping = {}
    contents_mapping_index = 1;
    for content in contents:
        content.index = contents_mapping_index;
        contents_mapping[contents_mapping_index] = content
        contents_mapping_index += 1;
    
func load_contents_mapping(stream: Stream) -> void:
    contents_mapping = {}
    for content in contents:
        content.index = -1;
    contents_mapping_index = 1;
    for _1 in range(stream.get_32()):
        var full_id = stream.get_string();
        if contents_indexed.has(full_id):
            contents_indexed[full_id].index = contents_mapping_index;
            contents_mapping[contents_mapping_index] = contents_indexed[full_id]
        contents_mapping_index += 1;
    for content in contents:
        if content.index == -1:
            content.index = contents_mapping_index;
            contents_mapping[contents_mapping_index] = content
            contents_mapping_index += 1;

func save_contents_mapping(stream: Stream) -> void:
    var values = contents_mapping.values()
    values.sort_custom(func(a, b):
        return b.index > a.index
    )
    stream.store_32(values.size())
    var current_index = 1;
    for value in values:
        current_index += 1;
        while current_index < value.index:
            stream.store_string("unk");
            current_index += 1;
        stream.store_string(value.full_id)
