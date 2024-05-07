class_name Vars_Client
extends Vars.Vars_Object

signal player_joined(player: Player)
signal player_left(player: Player)

var logger = Log.register_logger("Client_LogSource")

func join_local(if_not_headless: bool = true) -> Player:
    if if_not_headless and Vars.headless.headless_client:
        return null;
    var peer_data = Vars.server.PeerData.new()
    peer_data.peer_id = 1
    Vars.server.peers[1] = peer_data
    var player = Vars.players.get_player_by_token(Vars.configs.g("player-token", ""),
            update_player_data.bind({
                "peer_id": 1,
                "player_name": Vars.configs.g("player-name", ""),
            }))
    peer_data.player = player
    peer_data.joined = true
    Vars.game.current_player = player
    Vars.server.send_sync_packets(1)
    player_joined.emit(player)
    return player;

func disconnect_multiplayer() -> void:
    if Vars.server.multiplayer_port != -1:
        Vars.server.close_server()
        return
    Vars.server.peers = {}
    var peer = multiplayer.multiplayer_peer
    if not peer:
        return
    peer.close()

func update_player_data(player: Player, attrs = {}) -> void:
    if "player_name" in attrs:
        player.player_name = attrs["player_name"]
    if "peer_id" in attrs:
        player.peer_id = attrs["peer_id"]
        player.peer_data = Vars.server.peers[player.peer_id]

@rpc("authority", "call_local", "reliable")
func player_join(peer_id: int, player_id: int, attrs = {}) -> void:
    if "data" in attrs and attrs["data"] != null:
        Vars.players.player_datas[player_id] = attrs["data"]
    attrs.merge({
        "peer_id": peer_id,
    })
    var player = Vars.players.get_player(player_id, update_player_data.bind(attrs))
    Vars.players.players[player_id] = player
    Vars.server.peers[peer_id].player = player
    Vars.server.peers[peer_id].joined = true
    if peer_id == multiplayer.get_unique_id():
        Vars.game.current_player = player
    player_joined.emit(player)

@rpc("authority", "call_local", "reliable")
func player_leave(peer_id: int) -> void:
    Vars.players.players.erase(peer_id)

func get_sender_id() -> int:
    return multiplayer.get_remote_sender_id()

func get_unique_id() -> int:
    return multiplayer.get_unique_id()
