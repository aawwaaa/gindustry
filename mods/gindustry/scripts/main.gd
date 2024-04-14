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
    await load_items(content_list.items)

    # floors
    logger.info(tr("Loader_ModLoad_Blocks"))
    await load_floors(content_list.floors, root+"/contents/floors", floors)
    # overlays
    await load_floors(content_list.overlays, root+"/contents/overlays", overlays)
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
    var scripts = await Utils.load_contents_async(scripts_dir, types_list, "Loader_ModLoad_Scripts", logger.source);
    var types = {};
    for script in scripts:
        var inst = script.new();
        types[inst._get_type_id()] = script;
    return types

func load_floors(list: Array[String], prefix: String, target: Dictionary) -> void:
    var contents = await Utils.load_contents_async(prefix, list, "Loader_ModLoad_Floors", logger.source);
    var sorted_by_tilemap_texture: Dictionary = {}
    for content in contents:
        var texture = content.tilemap_texture
        if not sorted_by_tilemap_texture.has(texture):
            sorted_by_tilemap_texture[texture] = []
        sorted_by_tilemap_texture[texture].append(content)
    for texture in sorted_by_tilemap_texture:
        var source = TileSetAtlasSource.new();
        source.texture = texture;
        source.texture_region_size = Global.TILE_SIZE_VECTOR;
        var source_id = Floor.FLOORS.add_source(source);
        for content in sorted_by_tilemap_texture[texture]:
            source.create_tile(content.tile_coords)
            for id in range(1, Global.MAX_LAYERS):
                source.create_alternative_tile(content.tile_coords, id);
            content.tile_source_id = source_id
            if content is Gindustry_Floor or content is Gindustry_Overlay:
                content._init_source(source)
            var icon = AtlasTexture.new()
            icon.atlas = texture
            icon.region = Rect2(content.tile_coords * Global.TILE_SIZE_VECTOR, Global.TILE_SIZE_VECTOR)
            content.icon = icon
            Contents.register_content(content);
            target[content.id] = content;

func load_items(list: Array[String]) -> void:
    logger.info(tr("Loader_ModLoad_Items"))
    var items_contents = await Utils.load_contents_async(root+"/contents/items", list, "Loader_ModLoad_Items", logger.source);
    for item in items_contents:
        items[item.id] = item;
        Contents.register_content(item)

func load_entities(list: Array[String]) -> void:
    logger.info(tr("Loader_ModLoad_Entities"))
    var entities_contents = await Utils.load_contents_async(root+"/contents/entities", list, "Loader_ModLoad_Entities", logger.source);
    for entity in entities_contents:
        entities[entity.id] = entity;
        Contents.register_content(entity)

func load_buildings(list: Array[String]) -> void:
    var buildings_contents = await Utils.load_contents_async(root+"/contents/buildings", list, "Loader_ModLoad_Buildings", logger.source);
    for building in buildings_contents:
        buildings[building.id] = building;
        Contents.register_content(building)

func load_presets(list: Array[String]) -> void:
    logger.info(tr("Loader_ModLoad_Presets"))
    var presets = await Utils.load_contents_async(root+"/contents/presets", list, "Loader_ModLoad_Presets", logger.source);
    var presets_group = Presets.register_preset_group("Gindustry_Presets")
    for preset in presets:
        presets_group.add(preset);

func load_translations(list: Array[String]) -> void:
    logger.info(tr("Loader_ModLoad_Translations"))
    var translations = await Utils.load_contents_async(root+"/bundles", list, "Loader_ModLoad_Translations", logger.source);
    for translation in translations:
        Utils.merge_translations(translation)
