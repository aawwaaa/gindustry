class_name DataBlockProcessor
extends RefCounted

# Background:
#   In RPC environment, I need transfer large datas from client to server
#   I already implemented PacketStream for split data as packets
# Requirements:
#   Double direction large data transfer
#   Sync progress in client and server(current/total sent)
#       You should add this to every transfer packet
#   Multi data blocks sending in same time
#   Required methods:
#       send_data(data_name: String) -> PacketStreamMod
#       handle_rpc(args: Array[Variant]) -> void
#           For process data packet sends from this class
#           It will be call when another side called send_rpc
#       get_data_blocks(data_name: String) -> DataBlocks
#       get_all_data_blocks() -> Array[DataBlocks]
#   Signals:
#       new_data_transfer(data_name: String, blocks: DataBlocks)
#           Emit when it received a new data transfer
#       data_transfer_progress_changed(data_name: String, blocks: DataBlocks)
#       data_transfer_complete(data_name: String, blocks: DataBlocks)
#       send_rpc(args: Array[Variant])
#           Emit this to send rpc call
#   You need add other fields, methods and signals for implemention

class DataBlocks extends RefCounted:
    signal receive_complete(data_name: String, blocks: DataBlocks)
    signal progress_changed(data_name: String, blocks: DataBlocks)

    var processor: DataBlockProcessor
    var name: String
    var current_received: int = 0
    var server_sended: int = 0
    var completed: bool = false
    var server_ended: bool = false

    var received_datas: Dictionary
    
    func get_received() -> PackedByteArray:
        if not completed: return PackedByteArray()
        var buf = PackedByteArray()
        for index in server_sended:
            buf.append_array(received_datas[index])
        return buf

    func as_stream() -> ByteArrayStream:
        return ByteArrayStream.new(get_received())

    func finish() -> void:
        processor.data_blcoks_dict.erase(name)
    
    func handle_data(id: int, data: PackedByteArray) -> void:
        received_datas[id] = data
        while received_datas.has(current_received + 1):
            current_received += 1
        progress_changed.emit(name, self)
        if server_ended and current_received == server_sended:
            completed = true
            receive_complete.emit(name, self)

    func handle_statupd(id: int) -> void:
        server_sended = id
        progress_changed.emit(name, self)

    func handle_end(id: int) -> void:
        server_sended = id
        server_ended = true
        if current_received == id:
            completed = true
            receive_complete.emit(name, self)

class PacketStreamMod extends PacketStream:
    # Methods:
    #   close() -> void # flush, close stream, send completed
    # You need add other fields and methods for implemention
    var processor: DataBlockProcessor
    var name: String
    var packet_id: int = 0

    func close() -> void:
        super.close()
        processor.send_rpc.emit(["tranend", name, packet_id - 1])

    func _init() -> void:
        send_packet.connect(_on_send_packet)

    func _on_send_packet(data: PackedByteArray) -> void:
        processor.send_rpc_unreliable.emit(["statupd", name, packet_id])
        processor.send_rpc.emit(["data", name, packet_id, data])
        packet_id += 1

signal new_data_transfer(data_name: String, blocks: DataBlocks)
signal data_transfer_progress_changed(data_name: String, blocks: DataBlocks)
signal data_transfer_complete(data_name: String, blocks: DataBlocks)
signal send_rpc(args: Array[Variant])
signal send_rpc_unreliable(args: Array[Variant])

var data_blcoks_dict: Dictionary = {}

func send_data(data_name: String) -> PacketStreamMod:
    var stream = PacketStreamMod.new()
    stream.processor = self
    stream.name = data_name
    send_rpc.emit(["trannew", data_name])
    return stream

func handle_rpc(args: Array[Variant]) -> void:
    match args:
        ["trannew", var data_name]:
            var block = DataBlocks.new()
            block.processor = self
            block.name = data_name
            data_blcoks_dict[data_name] = block
            block.receive_complete.connect(func(a1, a2): data_transfer_complete.emit(a1, a2))
            block.progress_changed.connect(func(a1, a2): data_transfer_progress_changed.emit(a1, a2))
            new_data_transfer.emit(data_name, block)
        ["statupd", var data_name, var packet_id]:
            if not data_blcoks_dict.has(data_name): return
            data_blcoks_dict[data_name].handle_statupd(packet_id)
        ["data", var data_name, var packet_id, var data]:
            if not data_blcoks_dict.has(data_name): return
            data_blcoks_dict[data_name].handle_data(packet_id, data)
        ["tranend", var data_name, var packet_id]:
            if not data_blcoks_dict.has(data_name): return
            data_blcoks_dict[data_name].handle_end(packet_id)
        _:
            pass

func get_data_blocks(data_name: String) -> DataBlocks:
    return data_blcoks_dict.get(data_name, null)

func get_all_data_blocks() -> Array[DataBlocks]:
    return data_blcoks_dict.values()
