class_name Builtin
extends Node

static var entity: Dictionary = {}

func start_load() -> void:
    Contents.current_loading_mod = Mod.new(load("res://contents/builtin.tres"))
    InputHandler.register_input_handler("desktop", InputHandler.InputHandlerMeta.new({
        "input_handler": DesktopInputHandler,
        "tr_name": "InputHandler_desktop",
    }))

    await load_type("resource_types/", [
        "building_category.tres",
        "building_attribute_type.tres",
        "consumer_type.tres",
        "provider_type.tres",
    ])
    await load_type("building_attributes/", [
        "assembler.tres"
    ])
    await load_type("building_categories/", [
        "battle.tres",
        "capture.tres",
        "transportation.tres",
        "power.tres",
        "factory.tres",
        "unit.tres",
        "struct.tres",
        "logic.tres",
        "research.tres",
        "misc.tres",
    ])

    await load_content(entity, "entities/", [
        "building_shadow_container/entity.tres",
    ])

func load_content(to: Dictionary, prefix: String, paths: Array[String]) -> void:
    var results = await Utils.load_contents_async("res://contents/" + prefix, paths)
    for content in results:
        Contents.register_content(content)
        to[content.id] = content

func load_type(prefix: String, paths: Array[String]) -> void:
    var results = await Utils.load_contents_async("res://contents/" + prefix, paths)
    for type in results:
        Types.register_type(type)
