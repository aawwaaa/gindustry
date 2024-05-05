class_name G_Client
extends G.G_Object

signal player_joined(player: Player)
signal player_left(player: Player)

var log_source = Log.register_log_source("Client_LogSource")

func join_local(if_not_headless: bool = true) -> Player:
    if if_not_headless and Global.headless_client:
        return null;
    var peer_data = MultiplayerServer.PeerData.new()
    peer_data.peer_id = 1
    MultiplayerServer.peers[1] = peer_data
    var player = Players.get_player_by_token(Global.configs.g("player-token", ""),
            update_player_data.bind({
                "peer_id": 1,
                "player_name": Global.configs.g("player-name", ""),
            }))
    peer_data.player = player
    peer_data.joined = true
    Game.current_player = player
    MultiplayerServer.send_sync_packets(1)
    player_joined.emit(player)
    return player;

func disconnect_multiplayer() -> void:
    if MultiplayerServer.multiplayer_port != -1:
        MultiplayerServer.close_server()
        return
    MultiplayerServer.peers = {}
    var peer = multiplayer.multiplayer_peer
    if not peer:
        return
    peer.close()

func update_player_data(player: Player, attrs = {}) -> void:
    if "player_name" in attrs:
        player.player_name = attrs["player_name"]
    if "peer_id" in attrs:
        player.peer_id = attrs["peer_id"]
        player.peer_data = MultiplayerServer.peers[player.peer_id]

@rpc("authority", "call_local", "reliable")
func player_join(peer_id: int, player_id: int, attrs = {}) -> void:
    if "data" in attrs and attrs["data"] != null:
        Players.player_datas[player_id] = attrs["data"]
    attrs.merge({
        "peer_id": peer_id,
    })
    var player = Players.get_player(player_id, update_player_data.bind(attrs))
    Players.players[player_id] = player
    MultiplayerServer.peers[peer_id].player = player
    MultiplayerServer.peers[peer_id].joined = true
    if peer_id == multiplayer.get_unique_id():
        Game.current_player = player
    player_joined.emit(player)

@rpc("authority", "call_local", "reliable")
func player_leave(peer_id: int) -> void:
    Players.players.erase(peer_id)
