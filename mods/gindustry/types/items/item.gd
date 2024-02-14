class_name Gindustry_Item
extends ItemType

static var default_options_item = {
    "item_scene": preload("res://types/world/item/item.tscn"),
};

func _get_type_id() -> String:
    return "item";

func _init_by_mod(content_id: String, atlas_texture: AtlasTexture, args: Array) -> Dictionary:
    id = content_id

    var options = {};
    for arg in args.slice(1):
        options.merge(arg);
    options.merge(default_options_item);
    
    texture = atlas_texture
    item_scene = options["item_scene"]

    return options
