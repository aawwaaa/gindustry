class_name Vars_Server
extends Vars.Vars_Object

signal client_request_join(peer_data: PeerData)
signal client_message(peer_data: PeerData, message: String)
signal client_request_auto_complete(peer_data: PeerData, message: String)

const PeerState = PeerData.PeerState
const MultiplayerState = Vars_Client.MultiplayerState
const DATA_BLOCK_PROCESSOR_CHANNEL = 1

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

func server_active() -> bool:
    return multiplayer_state in [
        MultiplayerState.SERVER_LOADING,
        MultiplayerState.SERVER_READY,
    ]

func reset() -> void:
    if local_joined: reset_local_join()
    if not server_active(): return
    for peer in peers:
        Vars.client.connection_refused.rpc_id(peer, "Client_Refused_ServerReseted")
        peer.reset_server()
    server_port = -1
    multiplayer.multiplayer_peer.close()
    peers.clear()
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
    call_deferred("server_ready") # TODO
    return err

func server_ready() -> void:
    if not server_active(): return
    multiplayer_state = MultiplayerState.SERVER_READY
    multiplayer.multiplayer_peer.refuse_new_connections = false
    logger.info(tr("Server_Ready"))

func sync(node: Node, method: StringName, args: Array[Variant]) -> void:
    for peer in peers:
        peer.sync(node, method, args)

func set_peer_state(peer_id: int, state: PeerState) -> void:
    Vars.server.set_peer_state_rpc.rpc(peer_id, state)

@rpc("any_peer", "call_remote", "reliable")
func request_join() -> void:
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
    peer_data.state = PeerState.CONNECTING
    client_request_join.emit(peer_data)
    Vars.client.continue_join.rpc_id(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func request_auto_complete(message: String) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
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

func has_peer_data(peer_id: int) -> bool:
    return peers.has(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func request_message(message: String) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    client_message.emit(get_peer_data(peer_id), message)

@rpc("any_peer", "call_remote", "reliable")
func request_debug_data_block() -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    var data = get_peer_data(peer_id)
    var stream = data.data_block_processor.send_data("debug")
    var rng = RandomNumberGenerator.new()
    for _1 in range(100000):
        stream.store_8(rng.randi_range(0, 255))
    stream.close()

@rpc("any_peer", "call_remote", "reliable")
func request_world_data() -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    var data = get_peer_data(peer_id)
    var stream = data.data_block_processor.send_data("world")
    Vars.game.save_game(stream, true)
    stream.close()

@rpc("any_peer", "call_remote", "reliable")
func request_sync_queue_data() -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    if not has_peer_data(peer_id): return
    var data = get_peer_data(peer_id)
    var stream = data.data_block_processor.send_data("sync_queue")
    # TODO
    stream.close()

func send_message(message: String) -> void:
    sync(Vars.client, "post_message", [message])

func create_peer_data(peer_id: int) -> PeerData:
    var peer_data = PeerData.new()
    peer_data.peer_id = peer_id
    peers[peer_id] = peer_data
    peer_data.init_server()
    return peer_data

func init_local_join() -> PeerData:
    local_joined = true
    var peer_data = create_peer_data(Vars.client.multiplayer.get_unique_id())
    # TODO continue local join ... -> call player_joined to all
    return peer_data

func reset_local_join() -> void:
    local_joined = false
