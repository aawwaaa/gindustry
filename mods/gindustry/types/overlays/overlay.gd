class_name Gindustry_Overlay
extends Overlay

@export var tilemap_texture: Texture2D;
@export_enum("ground", "water", "space", "none") var collision_type: String = "ground"

func _init_source(source: TileSetAtlasSource) -> void:
    self.tile_alter_ids = Gindustry_Floor.default_tile_alter_ids
    Gindustry_Floor.apply_collision_type(collision_type, source, tile_coords);
