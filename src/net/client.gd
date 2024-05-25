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

var logger: Log.Logger = Log.register_logger("Client_LogSource")

var peers: Dictionary = {}
var multiplayer_state: MultiplayerState:
    set(v): multiplayer_state = v; multiplayer_state_changed.emit(v, multiplayer_state)
var local_joined: bool = false
var local_join_peer_data: PeerData

func client_active() -> bool:
    return multiplayer_state in [
        MultiplayerState.CLIENT_CONNECTING,
        MultiplayerState.CLIENT_RECEIVING,
        MultiplayerState.CLIENT_CATCTINGUP,
        MultiplayerState.CLIENT_CONNECTED,
    ]

func reset() -> void:
    if not client_active(): return
    if multiplayer.has_multiplayer_peer():
        multiplayer.multiplayer_peer.close()
    multiplayer_state = MultiplayerState.IDLE
    logger.info(tr("Client_Reseted"))

@rpc("authority", "call_local", "reliable")
func set_peer_state_rpc(peer_id: int, state: PeerState) -> void:
    if not peers.has(peer_id): return
    peers[peer_id].state = state

@rpc("authority", "call_remote", "reliable")
func connection_refused(reason: String) -> void:
    logger.error(tr("Client_ConnectionRefused {reason}").format({
        reason = tr(reason)
    }))
    Vars.core.state.set_state(Vars_Core.State.MAIN_MENU)

func connect_to(host: String, port: int) -> Error:
    Vars.core.state.set_state(Vars_Core.State.LOADING_GAME)
    return OK

@rpc("authority", "call_remote", "reliable")
func message(msg: String) -> void:
    pass

@rpc("authority", "call_remote", "reliable")
func continue_join() -> void:
    pass

func join_local() -> Player:
    return null
