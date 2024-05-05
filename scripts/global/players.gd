class_name G_Players
extends G.G_Object

var player_tokens: Dictionary = {}
var player_datas: Dictionary = {}
var player_inc_id: int = 1

var players: Dictionary = {}
var players_node: Node;

var player_data_types: Dictionary = {}

var aes_context = AESContext.new()
var magic_number = "gindustry--|---|".to_ascii_buffer()

func _ready() -> void:
    players_node = Node.new();
    players_node.name = "Players"
    add_child(players_node)

func get_player(player_id: int, update_data: Callable = func(): pass) -> Player:
    if players.has(player_id):
        update_data.call(players[player_id])
        return players[player_id]
    if player_datas.has(player_id):
        return load_player(player_id, update_data)
    return create_player(player_id, update_data)

func create_player(player_id: int, update_data: Callable = func(): pass) -> Player:
    var player = Player.create();
    player.player_id = player_id
    player.init_player();
    players[player_id] = player;
    update_data.call(player)
    init_data_for(player)
    players_node.add_child(player);
    apply_data_for(player)
    return player;

func get_player_by_token(token: String, update_data: Callable = func(): pass) -> Player:
    var id = get_player_id_by_token(token)
    var player = get_player(id, update_data)
    return player

func get_player_id_by_token(token: String) -> int:
    if token not in player_tokens:
        var id = player_inc_id
        player_tokens[token] = id
        player_inc_id += 1
        return id
    return player_tokens[token]

func remove_player(player: Player) -> void:
    players.erase(player.player_id)
    player.queue_free()

func reset_players() -> void:
    player_inc_id = 1
    player_datas = {}
    player_tokens = {}
    players = {}
    for child in players_node.get_children():
        child.queue_free()

func register_player_data_type(type_id: String, type: GDScript) -> String:
    var id = G.contents.current_loading_mod.mod_info.id + "_" + type_id
    player_data_types[id] = type
    return id

func init_data_for(player: Player) -> void:
    for type in player_data_types:
        var inst = player_data_types[type].new()
        inst.player = player
        inst.player_data_type = type
        inst._init_data()
        inst._init_private_data()
        inst.name = type
        player.get_datas_node().add_child(inst)

func apply_data_for(player: Player) -> void:
    for child in player.get_datas_node().get_children():
        child._apply_data()
        if child.has_private_data:
            child._apply_private_data()

func load_player(player_id: int, update_data: Callable = func(): pass) -> Player:
    var data = player_datas[player_id]
    var stream = ByteArrayStream.new(data)
    var player = Player.create();
    player.player_id = player_id
    player.init_player();
    players[player_id] = player;
    update_data.call(player)
    for _1 in range(stream.get_32()):
        var type = stream.get_string()
        var inst = player_data_types[type].new()
        inst.player = player
        inst.player_data_type = type
        inst._load_data(stream)
        var has_private_data = stream.get_8() == 1
        if has_private_data:
            inst.has_private_data = true
            inst._load_private_data(stream)
        inst.name = type
        player.get_datas_node().add_child(inst)
    players_node.add_child(player);
    apply_data_for(player)
    return player;

func save_player(player: Player, with_private_data: bool = true) -> PackedByteArray:
    var array = PackedByteArray()
    var stream = ByteArrayStream.new(array)
    stream.store_32(player.get_datas_node().get_child_count())
    for child in player.get_datas_node().get_children():
        stream.store_string(child.player_data_type)
        child._save_data(stream)
        stream.store_8(1 if with_private_data else 0)
        if with_private_data:
            child._save_private_data(stream)
    return array

const current_data_version = 0

func load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return
    player_inc_id = stream.get_64()

    player_tokens = {}
    var aes_key = G.configs.g("token-mapping-key")
    for _1 in range(stream.get_64()):
        var token_buffer = stream.get_buffer(stream.get_32())
        token_buffer.resize(ceili(token_buffer.size() / 16.0) * 16)
        aes_context.start(AESContext.MODE_ECB_DECRYPT, aes_key)
        var token_decrypted = aes_context.update(token_buffer).get_string_from_ascii()
        player_tokens[token_decrypted] = stream.get_64()
        aes_context.finish() 
    var buffer = stream.get_buffer(stream.get_16())
    buffer.resize(ceili(buffer.size() / 16.0) * 16)
    aes_context.start(AESContext.MODE_ECB_DECRYPT, aes_key)
    var buffer_decrypted = aes_context.update(buffer)
    aes_context.finish()
    if buffer_decrypted != magic_number:
        player_tokens = {}
        player_tokens[G.configs.g("player-token")] = 1

    player_datas = {}
    for _1 in range(stream.get_64()):
        var player_id = stream.get_64()
        var player_data = stream.get_buffer(stream.get_64())
        player_datas[player_id] = player_data

func save_data(stream: Stream) -> void:
    stream.store_16(current_data_version)
    # version 0
    stream.store_64(player_inc_id)

    stream.store_64(player_tokens.size())
    var aes_key = G.configs.g("token-mapping-key")
    for token in player_tokens:
        var player_id = player_tokens[token]
        var token_buffer = token.to_ascii_buffer()
        token_buffer.resize(ceili(token_buffer.size() / 16.0) * 16)
        aes_context.start(AESContext.MODE_ECB_ENCRYPT, aes_key)
        var token_encrypted = aes_context.update(token_buffer)
        aes_context.finish()
        stream.store_32(token_encrypted.size())
        stream.store_buffer(token_encrypted)
        stream.store_64(player_id)
    aes_context.start(AESContext.MODE_ECB_ENCRYPT, aes_key)
    var buffer = aes_context.update(magic_number)
    aes_context.finish()
    stream.store_16(buffer.size())
    stream.store_buffer(buffer)

    for player_id in players:
        var player = players[player_id]
        player_datas[player_id] = save_player(player, true)

    stream.store_64(player_datas.size())
    for player_id in player_datas:
        stream.store_64(player_id)
        stream.store_64(player_datas[player_id].size())
        stream.store_buffer(player_datas[player_id])

func save_data_client(stream: Stream) -> void:
    stream.store_16(current_data_version)
    # version 0
    stream.store_64(player_inc_id)

    stream.store_64(0)
    var buffer = PackedByteArray()
    stream.store_16(buffer.size())
    stream.store_buffer(buffer)

    var datas = {}
    for player_id in players:
        var player = players[player_id]
        datas[player_id] = save_player(player, false)

    stream.store_64(players.size())
    for player_id in players:
        stream.store_64(player_id)
        stream.store_64(datas[player_id].size())
        stream.store_buffer(datas[player_id])

