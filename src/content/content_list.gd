class_name ContentList
extends Resource

@export var base_path: String = "res://"
@export var types: Array[String] = []
@export var contents: Array[String] = []

func load_all() -> void:
    var results = await Utils.load_contents_async(base_path, types)
    for type in results:
        Vars.types.register_type(type)

    results = await Utils.load_contents_async(base_path, contents)
    for content in results:
        Vars.contents.register_content(content)

