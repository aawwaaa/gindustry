extends ContentCategory

func _data() -> void:
    super._data()
    id = "uncategoried"

    order = 1_000_000

func _assign() -> void:
    super._assign()
    ContentCategory.UNCATEGORIED = self

func _load_assets() -> void:
    icon = AtlasTexture.new()
    icon.atlas = load(mod.to_absolute("/assets/content_types.png"))
    icon.region = Rect2(0, 0, 32, 32)
