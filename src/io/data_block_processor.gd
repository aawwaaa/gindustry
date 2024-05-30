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
    # Methods:
    #   get_received() -> PackedByteArray
    #   as_stream() -> ByteArrayStream
    #   finish() -> void # free this object
    # Fields:
    #   current_received: int
    #   server_sended: int
    #   completed: bool
    # You need add other fields, methods and signals for implemention
    pass

class PacketStreamMod extends PacketStream:
    # Methods:
    #   close() -> void # flush, close stream, send completed
    # You need add other fields and methods for implemention
    var processor: DataBlockProcessor
    var name: String

    func close() -> void:
        super.close()
        pass

    func _init() -> void:
        pass

signal new_data_transfer(data_name: String, blocks: DataBlocks)
signal data_transfer_progress_changed(data_name: String, blocks: DataBlocks)
signal data_transfer_complete(data_name: String, blocks: DataBlocks)
signal send_rpc(args: Array[Variant])

var data_blcoks_dict: Dictionary = {}

func send_data(data_name: String) -> PacketStreamMod:
    var stream = PacketStreamMod.new()
    stream.processor = self
    stream.name = data_name
    send_rpc.emit(["new_transfer", data_name])
    return stream
