class_name Gindustry_TemplateOverlay
extends Overlay

func _get_type_id() -> String:
    return "";

func _init_by_mod(content_id: String, _source: TileSetAtlasSource, pos: Vector2i, args: Array) -> Dictionary:
    self.id = content_id;
    self.tile_coords = pos;
    self.tile_alter_ids = Gindustry_TemplateFloor.default_tile_alter_ids
    var options = {};
    for arg in args.slice(1):
        options.merge(arg);
    return options

