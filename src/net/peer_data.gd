class_name PeerData
extends RefCounted

signal peer_state_changed(state: PeerState, from: PeerState);

enum PeerState{
    DISCONNECTED,
    CONNECTING,
    RECEIVING,
    CATCHINGUP,
    CONNECTED
}

var peer_id: int = -1
var player: Player

var state: PeerState = PeerState.DISCONNECTED:
    set(v): state = v; peer_state_changed.emit(v, state)
