extends Gindustry_Item

@export var floor_type: Floor;

static var default_options_test_item = {
    "floor_type": "gindustry_floor_grass"
};

func _get_type_id() -> String:
    return "test_item";

func _init_by_mod(content_id: String, atlas_texture: AtlasTexture, args: Array) -> Dictionary:
    var options = super._init_by_mod(content_id, atlas_texture, args);
    options.merge(default_options_item);

    useable = true
    use_scene = preload("res://mods/gindustry/types/item_uses/test_use.tscn")

    Contents.wait_for_content(options["floor_type"], func(v): floor_type = v)

    return options
