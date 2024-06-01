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

var sync_queue: PackedByteArray = PackedByteArray()
var wbas: ByteArrayStream = null;

var data_block_processor: DataBlockProcessor

func call_remote(name: StringName, args: Array = []) -> void:
    if peer_id == Vars.client.multiplayer.get_unique_id():
        Vars.client.callv(name, args)
        return
    Vars.client.rpc_id.bindv(args).call(peer_id, name)

func sync(node: Node, method: StringName, args: Array[Variant]) -> void:
    if peer_id == Vars.client.multiplayer.get_unique_id():
        node.callv(method, args)
        return
    var serialized = Utils.serialize.serialize_args(args)
    if state in [PeerState.RECEIVING, PeerState.CONNECTING]:
        wbas.store_string(node.get_path())
        wbas.store_string(method)
        wbas.store_16(args.size())
        for i in args.size():
            wbas.store_string(serialized["types"][i])
            wbas.store_var(serialized["args"][i])
        return
    var cargs = [node.get_path(), method, serialized["args"], serialized["types"]]
    if state == PeerState.CATCHINGUP:
        call_remote("append_sync_queue", cargs)
        return
    call_remote("sync_receive", cargs)

func init_client() -> void:
    pass

func init_server() -> void:
    wbas = ByteArrayStream.new(sync_queue)
    data_block_processor = DataBlockProcessor.new()
    data_block_processor.send_rpc.connect(func(args): call_remote("dbp", [args]))
    data_block_processor.send_rpc_unreliable.connect(func(args): call_remote("dbpur", [args]))

func reset_client() -> void:
    pass

func reset_server() -> void:
    pass
