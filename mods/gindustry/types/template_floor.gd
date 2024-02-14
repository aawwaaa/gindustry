class_name Gindustry_TemplateFloor
extends Floor

static var default_tile_alter_ids: Array[int] = []:
    get:
        if default_tile_alter_ids.size() == 0:
            for layer_id in range(Global.MAX_LAYERS):
                default_tile_alter_ids.append(layer_id)
        return default_tile_alter_ids

func _get_type_id() -> String:
    return "";

func _init_by_mod(content_id: String, _source: TileSetAtlasSource, pos: Vector2i, args: Array) -> Dictionary:
    self.id = content_id;
    self.tile_coords = pos;
    self.tile_alter_ids = default_tile_alter_ids
    var options = {};
    for arg in args.slice(1):
        options.merge(arg);
    return options

static func apply_collision_type(collision_type: String, source: TileSetAtlasSource, pos: Vector2i) -> void:
    match collision_type:
        "ground":
            for layer_id in range(Global.MAX_LAYERS):
                var data = source.get_tile_data(pos, layer_id);
                data.add_collision_polygon(layer_id);
                data.set_collision_polygon_points(layer_id, 0, Floor.WHOLE_TILE_POLYGON_POINTS)
        "space":
            # layer 0
            var data = source.get_tile_data(pos, 0);
            data.add_collision_polygon(0);
            data.set_collision_polygon_points(0, 0, Floor.WHOLE_TILE_POLYGON_POINTS)
            data.add_collision_polygon(1);
            data.set_collision_polygon_points(1, 0, Floor.WHOLE_TILE_POLYGON_POINTS)
        "water":
            # it's empty
            pass
        "none":
            # it's empty too
            pass
