class_name Gindustry_TestPreset
extends Preset

var chunk_load_source = load("res://mods/gindustry/contents/presets/test/chunk_load_source.gd")

func _show_description(node: ScrollContainer) -> void:
    var label = Label.new()
    label.text = tr("Gindustry_Presets_Test_Description")
    node.add_child(label)

func _init_preset() -> void:
    var world = Game.create_world();
    world.chunk_load_source = chunk_load_source.new();
    for x in range(-2, 3):
        for y in range(-2, 3):
            await world.get_chunk(Vector2i(x, y))

    var test_entity_1 = Gindustry.entities["test_entity_1"].create_entity()
    test_entity_1.main_node.position = Vector2(200, 200)
    world.add_entity(test_entity_1);
    return

    world.get_tile_or_null(Vector2i(-8, -8)) \
            .set_building(Gindustry.buildings["test"])

    world.get_tile_or_null(Vector2i(-4, -8)) \
            .set_building(Gindustry.buildings["test"], PI * 0.5)

    world.get_tile_or_null(Vector2i(-4, -4)) \
            .set_building(Gindustry.buildings["test"], PI)

    world.get_tile_or_null(Vector2i(-8, -4)) \
            .set_building(Gindustry.buildings["test"], PI * 1.5)
    
    var shadow = world.get_tile_or_null(Vector2i(-12, -4)) \
            .set_building_shadow(Gindustry.buildings["test"], PI * 1.5)
    shadow.shadow.build_progress = 0.5

func _init_after_world_load() -> void:
    var world = Game.root_world
    var player = Game.current_player
    if not player:
        return
    var player_entity = Gindustry.entities["player"].create_entity()
    player_entity.get_adapter("controller").add_controller(player.get_controller())
    world.add_entity(player_entity);
    
    for type in ["copper", "lead", "titanium", "thorium", "coal", "sand"]:
        var item = Gindustry.items[type].create_item()
        item.amount = 80
        player_entity.get_adapter("item")._add_item(item)

func _load_preset() -> void:
    await Game.signal_game_loaded
    var world = Game.root_world
    world.chunk_load_source = chunk_load_source.new();

