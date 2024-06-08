class_name Vars_Server
extends Vars.Vars_Object

signal client_request_join(peer_data: PeerData)
signal client_message(peer_data: PeerData, message: String)
signal client_request_auto_complete(peer_data: PeerData, message: String)

signal server_reset()

const PeerState = PeerData.PeerState
const MultiplayerState = Vars_Client.MultiplayerState
const DATA_BLOCK_PROCESSOR_CHANNEL = 1

const CATCHUP_TIME_DELTA = 3

var logger: Log.Logger = Log.register_logger("Server_LogSource")

var peers: Dictionary:
    get: return Vars.client.peers
var multiplayer_state: MultiplayerState:
    get: return Vars.client.multiplayer_state
    set(v): Vars.client.multiplayer_state = v
var local_joined: bool:
    get: return Vars.client.local_joined
    set(v): Vars.client.local_joined = v
var server_port: int = -1

var server_handler: ServerHandler

var time: float = 0

func _physics_process(delta: float) -> void:
    time += delta

func server_active() -> bool:
    return multiplayer_state in [
        MultiplayerState.SERVER_LOADING,
        MultiplayerState.SERVER_READY,
    ]

func reset() -> void:
    if local_joined: reset_local_join()
    if not server_active(): return
    server_reset.emit()
    server_handler.reset()
    for peer in peers:
        Vars.client.connection_refused.rpc_id(peer, "Client_Refused_ServerReseted")
        peer.reset_server()
    multiplayer.multiplayer_peer.close()
    peers.clear()
    server_port = -1
    server_handler = null
    logger.info(tr("Server_Reseted"))

func create_server(port: int) -> Error:
    var err = OK
    if server_active():
        logger.info(tr("Server_ServerAlreadyActive"))
        return ERR_ALREADY_IN_USE
    if Vars.client.client_active():
        logger.info(tr("Server_ClientAlreadyActive"))
        return ERR_BUSY
    server_port = port
    var peer = ENetMultiplayerPeer.new()
    err = peer.create_server(port)
    if err != OK:
        logger.info(tr("Server_CreationFailed {err}").format({err = error_string(err)}))
        return err
    peer.refuse_new_connections = true
    multiplayer.multiplayer_peer = peer
    multiplayer_state = MultiplayerState.SERVER_LOADING
    logger.info(tr("Server_Loading {port}").format({port = port}))
    server_handler = ServerHandler.create()
    add_child(server_handler)
    server_handler.load_server()
    return err

func server_ready() -> void:
    if not server_active(): return
    multiplayer_state = MultiplayerState.SERVER_READY
    multiplayer.multiplayer_peer.refuse_new_connections = false
    logger.info(tr("Server_Ready"))

func sync_node(node: Node, method: StringName, args: Array[Variant]) -> void:
    var pack = PeerData.ServerSyncPack.new(node, method, args)
    for peer in peers.values():
        peer.sync(pack)

func set_peer_state(peer_id: int, state: PeerState) -> void:
    Vars.server.set_peer_state_rpc.rpc(peer_id, state)

@rpc("any_peer", "call_remote", "reliable")
func request_join(data: Dictionary) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if multiplayer_state != MultiplayerState.SERVER_READY:
        logger.error(tr("Server_UnexpectedRequestJoin {sender}").format({
            sender = peer_id
        }))
        Vars.client.connection_refused.rpc_id(peer_id, \
                "Client_Refused_UnexpectedRequestJoin")
        multiplayer.peer.disconnect_peer(peer_id, true)
        return
    var peer_data = create_peer_data(peer_id)
    peer_data.apply(data)
    peer_data.state = PeerState.CONNECTING
    if not server_handler.client_request_join(peer_data):
        return
    client_request_join.emit(peer_data)
    peer_data.call_remote("continue_join")

@rpc("any_peer", "call_remote", "reliable")
func request_auto_complete(message: String) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    server_handler.client_request_auto_complete(get_peer_data(peer_id), message)
    client_request_auto_complete.emit(get_peer_data(peer_id), message)

@rpc("any_peer", "call_remote", "reliable", DATA_BLOCK_PROCESSOR_CHANNEL)
func dbp(args: Array[Variant]) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    get_peer_data(peer_id).data_block_processor.handle_rpc(args)

@rpc("any_peer", "call_remote", "unreliable", DATA_BLOCK_PROCESSOR_CHANNEL)
func dbpur(args: Array[Variant]) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    get_peer_data(peer_id).data_block_processor.handle_rpc_unreliable(args)

func get_peer_data(peer_id: int) -> PeerData:
    return peers.get(peer_id)

func create_peer_data(peer_id: int) -> PeerData:
    var peer_data = PeerData.new()
    peer_data.peer_id = peer_id
    peers[peer_id] = peer_data
    peer_data.init_server()
    return peer_data

func has_peer_data(peer_id: int) -> bool:
    return peers.has(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func request_send_message(message: String) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    if not server_handler.client_message(peer_id, message): return
    client_message.emit(get_peer_data(peer_id), message)

@rpc("any_peer", "call_remote", "reliable")
func request_world_data() -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    var data = get_peer_data(peer_id)
    if data.state == PeerState.CONNECTING:
        data.state = PeerState.RECEIVING
    var stream = data.data_block_processor.send_data("world")
    Vars.game.save_game(stream, true)
    stream.close()

@rpc("any_peer", "call_remote", "reliable")
func request_sync_queue_data() -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    var data = get_peer_data(peer_id)
    if data.state == PeerState.CONNECTING:
        data.state = PeerState.RECEIVING
    var stream = data.data_block_processor.send_data("sync_queue")
    data.send_sync_queue(stream)
    stream.close()

@rpc("any_peer", "call_remote", "reliable")
func request_start_catchup() -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    var data = get_peer_data(peer_id)
    data.state = PeerState.CATCHINGUP
    data.call_remote("start_catchup", [time - data.start_time])

@rpc("any_peer", "call_remote", "unreliable_ordered")
func report_catchup(counter: float) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    var data = get_peer_data(peer_id)
    if data.state != PeerState.CATCHINGUP: return
    data.catchup_counter = counter
    data.call_remote("report_catchup", [time - data.start_time])
    if counter >= time - data.start_time - CATCHUP_TIME_DELTA:
        data.call_remote("enter_game")
        data.state = PeerState.CONNECTED
        data.load_player()
        Vars.client.sync("player_joined_rpc", [peer_id, data.to_client()])

func send_message(message: String) -> void:
    Vars.client.post_message.rpc(message)

func _on_peer_disconnected(peer_id: int) -> void:
    if not has_peer_data(peer_id): return
    var data = get_peer_data(peer_id)
    data.reset_server()
    if data.state == PeerState.CONNECTED:
        Vars.client.sync("player_left_rpc", [peer_id])
        Vars.players.remove_player(data.player_id)
    peers.erase(peer_id)

func is_player_has_permission(player: Player, permission: String) -> bool:
    return server_handler.has_permission(player, permission) \
            if server_handler != null else true

func is_caller_has_permission(mp: MultiplayerAPI, permission: String) -> bool:
    var peer_id = mp.get_remote_sender_id()
    if not has_peer_data(peer_id): return false
    var data = get_peer_data(peer_id)
    if data.player == null: return false
    return server_handler.has_permission(data.player, permission)

func init_local_join() -> PeerData:
    local_joined = true
    var peer_data = create_peer_data(Vars.client.multiplayer.get_unique_id() \
            if server_active() else 1)
    return peer_data

func reset_local_join() -> void:
    local_joined = false
