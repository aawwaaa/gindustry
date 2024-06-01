class_name Vars_Client
extends Vars.Vars_Object

signal multiplayer_state_changed(state: MultiplayerState, from: MultiplayerState);
signal server_message(message: String);

const PeerState = PeerData.PeerState
enum MultiplayerState{
    IDLE,
    CLIENT_CONNECTING, CLIENT_RECEIVING,
    CLIENT_CATCTINGUP, CLIENT_CONNECTED,
    SERVER_LOADING, SERVER_READY,
}
const DATA_BLOCK_PROCESSOR_CHANNEL = 1

var logger: Log.Logger = Log.register_logger("Client_LogSource")

var peers: Dictionary = {}
var multiplayer_state: MultiplayerState:
    set(v): multiplayer_state = v; multiplayer_state_changed.emit(v, multiplayer_state)
var local_joined: bool = false
var local_join_peer_data: PeerData

var data_block_processor: DataBlockProcessor = DataBlockProcessor.new()

func _ready() -> void:
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    await get_tree().process_frame
    Vars.ui.message_panel.submit.connect(_on_message_panel_submit)
    Vars.ui.message_panel.request_auto_complete.connect(_on_message_panel_request_auto_comlete)

    data_block_processor.send_rpc.connect(func(args):
        call_remote("dbp", [args])
    )
    data_block_processor.send_rpc_unreliable.connect(func(args):
        call_remote("dbpur", [args])
    )

func client_active() -> bool:
    return multiplayer_state in [
        MultiplayerState.CLIENT_CONNECTING,
        MultiplayerState.CLIENT_RECEIVING,
        MultiplayerState.CLIENT_CATCTINGUP,
        MultiplayerState.CLIENT_CONNECTED,
    ]

func reset() -> void:
    if not client_active(): return
    for peer in peers:
        peer.reset_client()
    if multiplayer.has_multiplayer_peer():
        multiplayer.multiplayer_peer.close()
    multiplayer_state = MultiplayerState.IDLE
    logger.info(tr("Client_Reseted"))

func disconnect_from_server() -> void:
    reset()
    Vars.core.state.set_state(Vars_Core.State.MAIN_MENU)

func call_remote(name: StringName, args: Array = []) -> void:
    if Vars.server.local_joined:
        Vars.server.callv(name, args)
        return
    Vars.server.rpc_id.bindv(args).call(1, name)

@rpc("authority", "call_local", "reliable")
func set_peer_state_rpc(peer_id: int, state: PeerState) -> void:
    if not peers.has(peer_id): return
    peers[peer_id].state = state

@rpc("authority", "call_remote", "reliable")
func connection_refused(reason: String) -> void:
    var message = tr("Client_ConnectionRefused {reason}").format({
        reason = tr(reason)
    })
    logger.error(message)
    Vars.ui.message_panel.add_message(message)
    disconnect_from_server()

@rpc("authority", "call_remote", "reliable")
func dbp(args: Array[Variant]) -> void:
    data_block_processor.handle_rpc(args)

@rpc("authority", "call_remote", "reliable")
func dbpur(args: Array[Variant]) -> void:
    data_block_processor.handle_rpc(args)

func connect_to(host: String, port: int) -> Error:
    Vars.core.state.set_state(Vars_Core.State.LOADING_GAME)
    var peer = ENetMultiplayerPeer.new()
    var err = peer.create_client(host, port)
    var message := ""
    if err != OK:
        message = tr("Client_ConnectionFailed {err}").format({err = error_string(err)})
        logger.info(message)
        Vars.ui.message_panel.add_message(message)
        Vars.core.state.set_state(Vars_Core.State.MAIN_MENU)
        return err
    multiplayer.multiplayer_peer = peer
    multiplayer_state = MultiplayerState.CLIENT_CONNECTING
    message = tr("Client_Connecting {host}:{port}").format({host = host, port = port})
    logger.info(message)
    Vars.ui.message_panel.add_message(message)
    add_connect_timeout()
    return OK

func add_connect_timeout() -> void:
    await get_tree().create_timer(5.0).timeout
    if multiplayer_state == MultiplayerState.CLIENT_CONNECTING:
        connection_refused("Client_Refused_Timeout")
        disconnect_from_server()

func _on_connected_to_server() -> void:
    multiplayer_state = MultiplayerState.CLIENT_RECEIVING
    logger.info(tr("Client_ConnectedToServer"))
    call_remote("request_join")

@rpc("authority", "call_remote", "reliable")
func post_message(msg: String) -> void:
    server_message.emit(msg)
    Vars.ui.message_panel.add_message(msg)

@rpc("authority", "call_remote", "reliable")
func set_auto_complete(msg: String) -> void:
    Vars.ui.message_panel.set_input(msg)

func _on_message_panel_submit(message: String) -> void:
    call_remote("request_message", [message])

func _on_message_panel_request_auto_comlete(message: String) -> void:
    call_remote("request_auto_complete", [message])

@rpc("authority", "call_remote", "reliable")
func set_prompt(prompt: String) -> void:
    Vars.ui.message_panel.set_prompt(prompt)

@rpc("authority", "call_remote", "reliable")
func sync_receive(path: NodePath, method: StringName, args: Array[Variant], types: Array) -> void:
    var node = Vars.tree.root.get_node(path)
    if not node: return
    if not method.ends_with("_rpc"): return
    var unserialized = Utils.serialize.unserialize_args(args, types)
    node.callv(method, unserialized)

@rpc("authority", "call_remote", "reliable")
func continue_join() -> void:
    call_remote("request_debug_data_block")
    # Request: player list, world data(data block), sync queue(data block)
    pass

@rpc("authority", "call_remote", "reliable")
func append_sync_queue(path: NodePath, method: StringName, args: Array[Variant], types: Array) -> void:
    # TODO
    pass

@rpc("authority", "call_remote", "reliable")
func player_joined(peer_id: int, data: Dictionary) -> void:
    # TODO
    # TODO if exists, use already exists
    pass

@rpc("authority", "call_remote", "reliable")
func player_left(peer_id: int) -> void:
    # TODO
    pass

func join_local() -> Player:
    return null
