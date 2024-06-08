class_name Vars_Client
extends Vars.Vars_Object

signal multiplayer_state_changed(state: MultiplayerState, from: MultiplayerState);
signal server_message(message: String);
signal prepare_join_data(data: Dictionary)

signal player_joined(player: Player);
signal player_left(player: Player);

const PLAYER_TOKEN_CONFIG = "player/player_token"
static var player_token_key = ConfigsGroup.ConfigKey.new(PLAYER_TOKEN_CONFIG, "")
const PLAYER_NAME_CONFIG = "player/player_name"
static var player_name_key = ConfigsGroup.ConfigKey.new(PLAYER_NAME_CONFIG, "Player")

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
var data_receive_progresses: Dictionary = {}
var sync_queue_received: bool = false
var world_data_received: bool = false

var catchup_controller: CatchupController
var sync_queue: Array[PeerData.ClientSyncPack] = []

func _ready() -> void:
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

    catchup_controller = CatchupController.new()
    catchup_controller.name = "CatchupController"
    add_child(catchup_controller)
    await get_tree().process_frame
    Vars.ui.message_panel.submit.connect(_on_message_panel_submit)
    Vars.ui.message_panel.request_auto_complete.connect(_on_message_panel_request_auto_comlete)
    reset()

    data_block_processor.send_rpc.connect(func(args):
        call_remote("dbp", [args])
    )
    data_block_processor.send_rpc_unreliable.connect(func(args):
        call_remote("dbpur", [args])
    )
    data_block_processor.new_data_transfer.connect(_on_new_data_transfer)
    data_block_processor.data_transfer_progress_changed.connect(_on_data_transfer_progress_changed)
    data_block_processor.data_transfer_complete.connect(_on_data_transfer_complete)

func _process(delta: float) -> void:
    if multiplayer_state == MultiplayerState.CLIENT_CATCTINGUP:
        process_catchup(delta)

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
    if not Vars.server.server_active():
        peers.clear()
    if multiplayer.has_multiplayer_peer():
        multiplayer.multiplayer_peer.close()
    for progress in data_receive_progresses:
        progress.finish()
    data_receive_progresses.clear()
    if catchup_controller.started:
        catchup_controller.stop()
        catchup_controller.auto_stop = true
    multiplayer_state = MultiplayerState.IDLE
    sync_queue_received = false
    world_data_received = false
    sync_queue = []
    data_block_processor.reset()
    logger.info(tr("Client_Reseted"))

func disconnect_from_server() -> void:
    Vars.game.reset_to_menu()

func call_remote(method_name: StringName, args: Array = []) -> void:
    if Vars.server.local_joined:
        Vars.server.callv(method_name, args)
        return
    Vars.server.rpc_id.bindv(args).call(1, method_name)

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
    await get_tree().create_timer(5.0, true, false, true).timeout
    if multiplayer_state == MultiplayerState.CLIENT_CONNECTING:
        connection_refused("Client_Refused_Timeout")

func create_join_data() -> Dictionary:
    var data = {
        "player_name": Vars.configs.k(player_name_key),
        "player_token": Vars.configs.k(player_token_key),
    }
    prepare_join_data.emit(data)
    return data

func _on_connected_to_server() -> void:
    multiplayer_state = MultiplayerState.CLIENT_RECEIVING
    logger.info(tr("Client_ConnectedToServer"))
    var join_data = create_join_data()
    call_remote("request_join", [join_data])
    # -> continue_join
    # -> connection_refused
    # -> post_message -> ...

func _on_connection_failed() -> void:
    connection_refused("Client_Refused_ConnectionFailed")

func _on_server_disconnected() -> void:
    connection_refused("Client_Refused_Disconnected")

@rpc("authority", "call_local", "reliable")
func post_message(msg: String) -> void:
    server_message.emit(msg)
    if Vars.headless.headless_client:
        logger.info(tr("Client_ServerMessage {message}").format({
            message = msg
        }))
    else:
        Vars.ui.message_panel.add_message(msg)

@rpc("authority", "call_remote", "reliable")
func set_auto_complete(msg: String) -> void:
    Vars.ui.message_panel.set_input(msg)

func _on_message_panel_submit(message: String) -> void:
    call_remote("request_send_message", [message])

func _on_message_panel_request_auto_comlete(message: String) -> void:
    call_remote("request_auto_complete", [message])

@rpc("authority", "call_remote", "reliable")
func set_prompt(prompt: String) -> void:
    Vars.ui.message_panel.set_prompt(prompt)

@rpc("authority", "call_remote", "reliable")
func show_message_input() -> void:
    Vars.ui.message_panel.show_input()

@rpc("authority", "call_remote", "reliable")
func continue_join() -> void:
    call_remote("request_world_data")
    call_remote("request_sync_queue_data")
    # -> _on_data_transfer_complete

func _on_new_data_transfer(data_name: String, _blocks: DataBlockProcessor.DataBlocks) -> void:
    if data_name not in ["world", "sync_queue"]: return
    data_receive_progresses[data_name] = Log.register_progress_tracker(0,
        tr("Client_ReceivingData {name}").format({name = data_name}),
        logger.source)

func _on_data_transfer_progress_changed(data_name: String, blocks: DataBlockProcessor.DataBlocks) -> void:
    if data_name not in ["world", "sync_queue"]: return
    data_receive_progresses[data_name].total = blocks.server_sended
    data_receive_progresses[data_name].progress = blocks.current_received

func _on_data_transfer_complete(data_name: String, blocks: DataBlockProcessor.DataBlocks) -> void:
    if data_name not in ["world", "sync_queue"]: return
    data_receive_progresses[data_name].finish()
    data_receive_progresses.erase(data_name)
    match data_name:
        "world":
            load_world(blocks.as_stream())
        "sync_queue":
            load_sync_queue(blocks.as_stream())
    blocks.finish()
    # -> check_finished

func load_world(stream: ByteArrayStream) -> void:
    var err = Vars.game.load_game(stream)
    world_data_received = true
    if err: disconnect_from_server()
    else: check_finished()

func load_sync_queue(stream: ByteArrayStream) -> void:
    var arr = PeerData.ClientSyncPack.load_array(stream)
    if PeerData.ClientSyncPack.err:
        disconnect_from_server()
        return
    sync_queue.append_array(arr)
    sync_queue.sort_custom(func(a, b): return a.time < b.time)
    sync_queue_received = true
    check_finished()

@rpc("authority", "call_remote", "reliable")
func sync_receive(data: PackedByteArray) -> void:
    Vars.temp.bas.load(data)
    var pack = PeerData.ClientSyncPack.load(Vars.temp.bas)
    Vars.temp.bas.clear()
    if PeerData.ClientSyncPack.err:
        disconnect_from_server()
        return
    pack.run()

@rpc("authority", "call_remote", "reliable")
func append_sync_queue(data: PackedByteArray) -> void:
    Vars.temp.bas.load(data)
    var pack = PeerData.ClientSyncPack.load(Vars.temp.bas)
    Vars.temp.bas.clear()
    if PeerData.ClientSyncPack.err:
        disconnect_from_server()
        return
    sync_queue.append(pack)

func check_finished() -> void:
    if not world_data_received: return
    if not sync_queue_received: return
    logger.info(tr("Client_ReadyForCatchup"))
    Vars.game.make_ready_game()
    call_remote("request_start_catchup")

@rpc("authority", "call_remote", "reliable")
func start_catchup(duration: float) -> void:
    multiplayer_state = MultiplayerState.CLIENT_CATCTINGUP
    catchup_controller.mark_start()
    catchup_controller.set_duration(duration)
    # catchup_controller.auto_stop = false
    catchup_controller.start()
    catchup_controller.finished.connect(func():
        call_remote("report_catchup", [catchup_controller.counter])
    )

@rpc("authority", "call_remote", "unreliable_ordered")
func report_catchup(duration: float) -> void:
    catchup_controller.set_duration(duration)

func process_catchup(_delta: float) -> void:
    if not catchup_controller.started: return
    call_remote("report_catchup", [catchup_controller.counter])

@rpc("authority", "call_remote", "reliable")
func enter_game() -> void:
    catchup_controller.stop()
    multiplayer_state = MultiplayerState.CLIENT_CONNECTED
    sync_queue = []
    Vars.game.enter_game()

func player_joined_rpc(peer_id: int, peer_data: Dictionary) -> void:
    var peer = peers[peer_id] if peer_id in peers else PeerData.new()
    if local_joined:
        player_joined.emit(peer.player)
        return
    peer.peer_id = peer_id
    peer.apply_client(peer_data)
    var player_id = peer_data["player_id"]
    if "player_data" in peer_data:
        Vars.players.player_datas[player_id] = peer_data["player_data"]
    peer.load_player()
    if peer_id == multiplayer.get_unique_id():
        current_player(player_id)
    player_joined.emit(peer.player)

func player_left_rpc(peer_id: int) -> void:
    if peer_id not in peers: return
    var data = peers[peer_id]
    player_left.emit(data.player)
    if local_joined:
        peers[peer_id].reset_client()
        return
    Vars.players.remove_player(data.player_id)
    data.reset_client()
    peers.erase(peer_id)

func current_player(id: int) -> void:
    Vars.game.player = Vars.players.get_player(id)

func catchup_test_rpc(message: String) -> void:
    var msg = tr("Client_CatchupTest {message}").format({message = message})
    logger.info(msg)
    post_message(msg)

func join_local(if_not_headless: bool = true) -> Player:
    if if_not_headless and Vars.headless.headless_client: return
    var peer = Vars.server.init_local_join()
    sync_queue_received = true
    world_data_received = true
    peer.apply(create_join_data())
    peer.state = PeerState.CONNECTED
    peer.load_player()
    sync("player_joined_rpc", [peer.peer_id, peer.to_client()])
    current_player(peer.player_id)
    return peer.player
