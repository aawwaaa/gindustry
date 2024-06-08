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

class ServerSyncPack extends RefCounted:
    var node: Node
    var path: NodePath
    var method: StringName
    var args: PackedByteArray
    var args_raw: Array

    func _init(p_node: Node, p_method: StringName, p_args: Array) -> void:
        node = p_node
        path = node.get_path()
        method = p_method
        args_raw = p_args
        args = Utils.serialize.serialize_as_buffer(p_args)

    func run() -> void:
        node.callv(method, args_raw)

    func save(stream: Stream, time: float) -> void:
        stream.store_float(time)
        stream.store_string(path)
        stream.store_string(method)
        stream.store_buffer(args)

class ServerSyncPackWithTime extends RefCounted:
    var time: float
    var pack: ServerSyncPack

    func _init(p_time: float, p_pack: ServerSyncPack) -> void:
        time = p_time
        pack = p_pack

    func save(stream: Stream) -> void:
        pack.save(stream, time)

class ClientSyncPack extends RefCounted:
    static var err: Error

    var time: float
    var node: Node
    var method: StringName
    var args: Array

    func _init(p_time: float, path: NodePath, p_method: StringName, p_args: Array) -> void:
        time = p_time
        node = Vars.tree.root.get_node(path)
        method = p_method
        args = p_args

    func run() -> void:
        if not method.ends_with("_rpc"):
            push_error("Invalid call to %s" % method)
            return
        node.callv(method, args)

    static func load(stream: Stream) -> ClientSyncPack:
        var t = stream.get_float()
        var p = stream.get_string()
        var m = stream.get_string()
        var a = Utils.serialize.unserialize(stream)
        err = Utils.serialize.err
        return ClientSyncPack.new(t, p, m, a)
    
    static func load_array(stream: Stream) -> Array[ClientSyncPack]:
        var arr: Array[ClientSyncPack] = []
        var size = stream.get_64()
        for _i in range(size):
            arr.append(ClientSyncPack.load(stream))
            if err: return []
        return arr

var peer_id: int = -1
var player: Player

var state: PeerState = PeerState.DISCONNECTED:
    set(v): state = v; peer_state_changed.emit(v, state)

var sync_queue: Array[ServerSyncPackWithTime] = []

var start_time: float = 0
var catchup_counter: float = 0
var data_block_processor: DataBlockProcessor

var data_raw: Dictionary

var player_token: String = "<No data>"
var player_name: String = "Player"

var player_id: int = -1

func call_remote(name: StringName, args: Array = []) -> void:
    if peer_id == Vars.client.multiplayer.get_unique_id():
        Vars.client.callv(name, args)
        return
    Vars.client.rpc_id.bindv(args).call(peer_id, name)

func sync(pack: ServerSyncPack) -> void:
    if peer_id == Vars.client.multiplayer.get_unique_id():
        pack.run()
        return
    var time = Vars.server.time - start_time
    if state == PeerState.CONNECTING:
        sync_queue.append(ServerSyncPackWithTime.new(time, pack))
        return
    Vars.temp.bas.clear()
    pack.save(Vars.temp.bas, time)
    var data = Vars.temp.bas.submit()
    if state in [PeerState.RECEIVING, PeerState.CATCHINGUP]:
        call_remote("append_sync_queue", [data])
        return
    call_remote("sync_receive", [data])

func send_sync_queue(stream: Stream) -> void:
    stream.store_64(sync_queue.size())
    for pack in sync_queue:
        pack.save(stream)
    sync_queue.clear()

func apply(data: Dictionary) -> void:
    data_raw = data
    apply_client(data)

    player_token = data["player_token"]
    player_id = Vars.players.get_player_id_by_token(player_token)

func to_client() -> Dictionary:
    var data = {
        "player_name": player_name,
        "player_id": player_id,
    }
    if player_id in Vars.players.player_datas:
        data["player_data"] = Vars.players.player_datas[player_id]
    return data

func apply_client(data: Dictionary) -> void:
    if data_raw.size() == 0: data_raw = data
    player_name = data["player_name"]
    player_id = data["player_id"] if "player_id" in data else -1

func load_player() -> void:
    Vars.players.get_player(player_id, func(p):
        player = p
        player.player_name = player_name
        player.peer_data = self
    )

func init_client() -> void:
    pass

func init_server() -> void:
    start_time = Vars.server.time
    data_block_processor = DataBlockProcessor.new()
    data_block_processor.send_rpc.connect(func(args): call_remote("dbp", [args]))
    data_block_processor.send_rpc_unreliable.connect(func(args): call_remote("dbpur", [args]))

func reset_client() -> void:
    pass

func reset_server() -> void:
    pass
