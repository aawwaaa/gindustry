class_name Gindustry
extends Mod

static var root = "res://mods/gindustry"
static var logger: Log.Logger;

static var items: Dictionary = {}

static var floors: Dictionary = {}
static var overlays: Dictionary = {}
static var buildings: Dictionary = {}

static var entities: Dictionary = {}

static var player_data_type: String;

func _init(info: ModInfo) -> void:
    super._init(info);
    logger = Log.register_log_source("Gindustry");

func _mod_init() -> void:
    #logger.info("Hello world from mod!")
    pass

func _load_contents() -> void:
    var content_list = load(root+"/scripts/content_list.gd").new()
    # items
    logger.info(tr("Loader_ModLoad_Items"))
    var items_image = (await Utils.load_contents_async(root+"/assets", ["/items.png"]))[0];
    await load_texture_atlas(items_image, Vector2i(32, 32), content_list.items, root+"/types/items/", "items_", items)

    # floors
    logger.info(tr("Loader_ModLoad_Blocks"))
    var floors_image = (await Utils.load_contents_async(root+"/assets", ["/floors.png"]))[0];
    await load_floors(floors_image, content_list.floors, root+"/types/floors/", "floor_", floors)
    # overlays
    var overlays_image = (await Utils.load_contents_async(root+"/assets", ["/overlays.png"]))[0];
    await load_floors(overlays_image, content_list.overlays, root+"/types/overlays/", "overlay_", overlays)
    # buildings
    await load_buildings(content_list.buildings)

    # entities
    await load_entities(content_list.entities)
        
    await load_presets(content_list.presets)
    await load_translations(content_list.translations);

    var player_data = load(root+"/types/player_data.gd")
    player_data_type = Players.register_player_data_type("player_data", player_data)

func _open_configs() -> Window:
    return super._open_configs();

func load_types(scripts_dir: String) -> Dictionary:
    var types_list: Array[String] = []
    var access = DirAccess.open(scripts_dir);
    access.list_dir_begin();
    var file_name = access.get_next();
    while file_name != "":
        types_list.append(file_name);
        file_name = access.get_next();
    access.list_dir_end();
    var scripts = await Utils.load_contents_async(scripts_dir, types_list);
    var types = {};
    for script in scripts:
        var inst = script.new();
        types[inst._get_type_id()] = script;
    return types

func load_texture_atlas(image: Texture2D, size: Vector2i, list: Dictionary, scripts_dir: String, prefix: String, target: Dictionary) -> void:
    var types = await load_types(scripts_dir)
    var width = image.get_width();
    var height = image.get_height();
    var keys = list.keys()
    @warning_ignore("integer_division")
    for y in range(height / size.y):
        @warning_ignore("integer_division")
        for x in range(width / size.x):
            var current = keys.pop_front();
            var args: Array = list[current]
            if args[0] == "skip":
                continue
            var atlas = AtlasTexture.new()
            atlas.atlas = image
            atlas.region = Rect2i(Vector2i(x, y) * size, size);
            var content = types[args[0]].new();
            content._init_by_mod(prefix + current, atlas, args);
            Contents.register_content(content);
            target[current] = content;

func load_floors(image: Texture2D, list: Dictionary, scripts_dir: String, prefix: String, target: Dictionary) -> void:
    var floor_types = await load_types(scripts_dir)
    var source = TileSetAtlasSource.new();
    source.texture = image;
    source.texture_region_size = Vector2i(Global.TILE_SIZE, Global.TILE_SIZE);
    var width = image.get_width();
    var height = image.get_height();
    var keys = list.keys()
    var tile_set = load("res://types/contents/floors.tres");
    var source_id = tile_set.add_source(source);
    @warning_ignore("integer_division")
    for y in range(height / source.texture_region_size.y):
        @warning_ignore("integer_division")
        for x in range(width / source.texture_region_size.x):
            var current = keys.pop_front();
            var args: Array = list[current]
            if args[0] == "skip":
                continue
            var pos = Vector2i(x, y);
            source.create_tile(pos);
            for id in range(1, Global.MAX_LAYERS):
                source.create_alternative_tile(pos, id);
            var content = floor_types[args[0]].new();
            content._init_by_mod(prefix + current, source, pos, args);
            content.tile_source_id = source_id;
            Contents.register_content(content);
            target[current] = content;

func load_entities(list: Array[String]) -> void:
    logger.info(tr("Loader_ModLoad_Entities"))
    var entities_contents = await Utils.load_contents_async(root+"/contents/entities", list);
    for entity in entities_contents:
        entities[entity.id] = entity;
        Contents.register_content(entity)

func load_buildings(list: Array[String]) -> void:
    var buildings_contents = await Utils.load_contents_async(root+"/contents/buildings", list);
    for building in buildings_contents:
        buildings[building.id] = building;
        Contents.register_content(building)

func load_presets(list: Array[String]) -> void:
    logger.info(tr("Loader_ModLoad_Presets"))
    var presets = await Utils.load_contents_async(root+"/contents/presets", list);
    var presets_group = Presets.register_preset_group("Gindustry")
    for preset in presets:
        presets_group.add(preset);

func load_translations(list: Array[String]) -> void:
    logger.info(tr("Loader_ModLoad_Translations"))
    var translations = await Utils.load_contents_async(root+"/bundles", list);
    for translation in translations:
        Utils.merge_translations(translation)
