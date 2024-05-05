class_name G_Client
extends G.G_Object

signal player_joined(player: Player)
signal player_left(player: Player)

var log_source = Log.register_log_source("Client_LogSource")

func join_local(if_not_headless: bool = true) -> Player:
    if if_not_headless and G.headless.headless_client:
        return null;
    var peer_data = G.server.PeerData.new()
    peer_data.peer_id = 1
    G.server.peers[1] = peer_data
    var player = G.players.get_player_by_token(G.configs.g("player-token", ""),
            update_player_data.bind({
                "peer_id": 1,
                "player_name": G.configs.g("player-name", ""),
            }))
    peer_data.player = player
    peer_data.joined = true
    G.game.current_player = player
    G.server.send_sync_packets(1)
    player_joined.emit(player)
    return player;

func disconnect_multiplayer() -> void:
    if G.server.multiplayer_port != -1:
        G.server.close_server()
        return
    G.server.peers = {}
    var peer = multiplayer.multiplayer_peer
    if not peer:
        return
    peer.close()

func update_player_data(player: Player, attrs = {}) -> void:
    if "player_name" in attrs:
        player.player_name = attrs["player_name"]
    if "peer_id" in attrs:
        player.peer_id = attrs["peer_id"]
        player.peer_data = G.server.peers[player.peer_id]

@rpc("authority", "call_local", "reliable")
func player_join(peer_id: int, player_id: int, attrs = {}) -> void:
    if "data" in attrs and attrs["data"] != null:
        G.players.player_datas[player_id] = attrs["data"]
    attrs.merge({
        "peer_id": peer_id,
    })
    var player = G.players.get_player(player_id, update_player_data.bind(attrs))
    G.players.players[player_id] = player
    G.server.peers[peer_id].player = player
    G.server.peers[peer_id].joined = true
    if peer_id == multiplayer.get_unique_id():
        G.game.current_player = player
    player_joined.emit(player)

@rpc("authority", "call_local", "reliable")
func player_leave(peer_id: int) -> void:
    G.players.players.erase(peer_id)

func get_sender_id() -> int:
    return multiplayer.get_remote_sender_id()

func get_unique_id() -> int:
    return multiplayer.get_unique_id()
