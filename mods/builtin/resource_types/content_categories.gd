extends Object

class ContentCategoryTemplate extends ContentCategory:
    static var category_atlas: Texture2D;

    var region: Rect2i

    func _load_assets() -> void:
        icon = AtlasTexture.new()
        icon.atlas = category_atlas
        icon.region = region

static var category_atlas: Texture2D;
static var region_index: int = 0
static var region_size: Vector2i = Vector2i(32, 32)

static func __resource__static_init(mod: Mod) -> void:
    category_atlas = mod.load_relative("/assets/content_categories.png")
    ContentCategoryTemplate.category_atlas = category_atlas
    region_index = 0

    ContentCategory.MISC = category("misc", 10_000)
    ContentCategory.RESOURCE = category("resource", 5_000)
    ContentCategory.TRANSPORTATION = category("transportation", 5_001)
    ContentCategory.PRODUCTION = category("production", 5_002)
    ContentCategory.MILITARY = category("military", 5_003)
    ContentCategory.MESH = category("mesh", 5_004)

static func category(id: String, order: int) -> ContentCategory:
    var c = ContentCategoryTemplate.new()
    c.id = id
    c.order = order
    @warning_ignore("integer_division")
    var cols = category_atlas.get_width() / region_size.x
    var x = (region_index % cols) * region_size.x
    var y = floori(region_index * 1.0 / cols) * region_size.y
    c.region = Rect2i(Vector2i(x, y), region_size)
    Vars.types.register_type(c)

    region_index += 1
    return c
