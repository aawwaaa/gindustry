extends Node

class PeerData extends RefCounted:
    var peer_id: int = -1;
    var player: Player = null;

    var player_name: String;
    var token: String;

    var joined: bool = false
    var packet_queue: Array = []

var multiplayer_port: int = -1;
var peers: Dictionary = {};

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func reset_server() -> void:
    for id in peers.keys():
        peers[id].free()
    peers.clear()

func start_server(port: int) -> void:
    if multiplayer_port != -1:
        push_error("MultiplayerServer has already started.")
        return
    reset_server()
    var peer = ENetMultiplayerPeer.new()
    multiplayer.multiplayer_peer = peer;
    peer.create_server(port, 256)
    multiplayer_port = port;

func _on_peer_connected(peer_id: int) -> void:
    peers[peer_id] = PeerData.new()
    peers[peer_id].peer_id = peer_id

func _on_peer_disconnected(peer_id: int) -> void:
    if not peers.has(peer_id):
        return
    peers[peer_id].free()
    peers.erase(peer_id)

func stop_server() -> void:
    if multiplayer_port == -1:
        push_error("MultiplayerServer haven't started yet.")
        return;
    var peer: ENetMultiplayerPeer = multiplayer.multiplayer_peer
    peer.close()
    reset_server()

@rpc("any_peer", "call_remote", "reliable")
func request_server_info() -> Dictionary:
    return {}

@rpc("any_peer", "call_remote", "reliable")
func request_join(uuid: String, player_name: String) -> void:
    var peer_id = multiplayer.get_remote_sender_id();
    # todo

func is_peer_admin(peer: int) -> bool:
    return peer == 1

# request connect(with uuid, name) -> confirmed -> request-world -> send-world -> send-packets -> create-player
# server-player-join(with name)

@rpc("any_peer", "call_remote", "reliable")
func ready_to_play() -> void:
    var id = multiplayer.get_remote_sender_id()
    if not peers.has(id) or peers[id].joined:
        return
    var peer_data = peers[id]
    var player_id = Players.get_player_id_by_token(peer_data.token)
    Multiplayer.player_join.rpc(id, player_id, {
        "player_name": peer_data.player_name,
        "data": Players.player_datas[player_id] if player_id in Players.player_datas else null,
    })
    send_sync_packets(id)

func serialize(args: Array) -> Dictionary:
    var types = Array()
    types.resize(args.size())
    types.fill(null)
    return {"args": args, "types": types}

func send_sync_packets(peer_id: int) -> void:
    if not peers.has(peer_id) or not peers[peer_id].joined:
        return
    if peer_id == multiplayer.get_unique_id():
        for packed in peers[peer_id].packet_queue:
            var node = packed[0]
            var inst = get_tree().root.get_node(node)
            var method = packed[1]
            var args = packed[2]
            var types = packed[3]
            inst.callv(method, Serialize.unserialize_args(args, types))
    else:
        for packed in peers[peer_id].packet_queue:
            var node = packed[0]
            var method = packed[1]
            var args = packed[2]
            var types = packed[3]
            rpc_sync_client.rpc_id(peer_id, node, method, args, types)
    peers[peer_id].packet_queue.clear()

func rpc_sync(node: Node, method: String, args: Array = []) -> void:
    var serialized = Serialize.serialize_args(args)
    var path = node.get_path_to(get_tree().root)
    rpc_sync_server.rpc_id(1, path, method, serialized["args"], serialized["types"])

@rpc("any_peer", "call_local", "reliable")
func rpc_sync_server(node: NodePath, method: String, args: Array, types: Array) -> void:
    var inst = get_tree().root.get_node(node)
    if multiplayer.get_remote_sender_id() != inst.get_multiplayer_authority():
        return
    var packed = [node, method, args, types]
    for peer in peers.keys():
        if not peers[peer].joined:
            peers[peer].packet_queue.append(packed)
            continue
        if peer == multiplayer.get_unique_id():
            inst.callv(method, Serialize.unserialize_args(args, types))
            continue
        rpc_sync_client.rpc_id(peer, node, method, args, types)

@rpc("authority", "call_remote", "reliable")
func rpc_sync_client(node: NodePath, method: String, args: Array, types: Array) -> void: 
    var inst = get_tree().root.get_node(node)
    inst.callv(method, Serialize.unserialize_args(args, types))
