extends Gindustry_TemplateFloor

static var default_options_floor = {
    "collision_type": "ground"
};

func _get_type_id() -> String:
    return "floor";

func _init_by_mod(content_id: String, source: TileSetAtlasSource, pos: Vector2i, args: Array) -> Dictionary:
    var options = super._init_by_mod(content_id, source, pos, args);
    options.merge(default_options_floor);
    
    Gindustry_TemplateFloor.apply_collision_type(options["collision_type"], source, pos);
    return options
