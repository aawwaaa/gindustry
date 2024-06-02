class_name Builtin
extends Node

static var entity: Dictionary = {}
static var building: Dictionary = {}
static var builtin_mod_info: ModInfo = load("res://contents/builtin.tres")

static func load_builtin() -> void:
    if builtin_mod_info.enabled: return
    builtin_mod_info.enabled = true

    Vars.mods.current_loading_mod = Mod.new(builtin_mod_info)
    
    Vars.mods.mod_info_list[builtin_mod_info.id] = builtin_mod_info
    Vars.mods.mod_inst_list[builtin_mod_info.id] = Vars.mods.current_loading_mod

static func start_load() -> void:
    Vars.mods.current_loading_mod = Vars.mods.mod_inst_list[builtin_mod_info.id]

    # InputHandler.register_input_handler("desktop", InputHandler.InputHandlerMeta.new({
    #     "input_handler": DesktopInputHandler,
    #     "tr_name": "InputHandler_desktop",
    # }))

    await load_type("resource_types/", [
        "building_category.tres",
        "building_attribute_type.tres",
        "consumer_type.tres",
        "provider_type.tres",
        "content_type.tres",
        "content_category.tres",
        "preset.tres",
        "tile_ore_type.tres"
    ])
    await load_type("content_types/", [
        # "building.tres",
        "content.tres",
        # "entity.tres",
        # "floor.tres",
        # "item.tres",
        # "overlay.tres",
        # "recipe.tres",
    ])
    await load_type("content_categories/", [
        "uncategoried.tres",
    ])
    await load_type("building_attributes/", [
        "assembler.tres",
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
    # await load_type("tile_ore_types/", [
    #     "item.tres",
    # ])

    # await load_content(entity, "entities/", [
    #     "building_shadow_container/entity.tres",
    # ])
    # await load_content(building, "buildings/", [
    #     "dropped_item/building.tres",
    #     "test_build/building.tres",
    # ])

static func load_content(to: Dictionary, prefix: String, paths: Array[String]) -> void:
    var results = await Utils.load_contents_async("res://contents/" + prefix, paths, "Loader_ModLoad_Contents", "Builtin")
    for content in results:
        Vars.contents.register_content(content)
        to[content.id] = content

static func load_type(prefix: String, paths: Array[String]) -> void:
    var results = await Utils.load_contents_async("res://contents/" + prefix, paths, "Loader_ModLoad_Types", "Builtin")
    for type in results:
        Vars.types.register_type(type)
