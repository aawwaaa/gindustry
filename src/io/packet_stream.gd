class_name PacketStream
extends Stream

signal send_packet(packet: PackedByteArray)

var buffer_send_limit = 1024 * 16
var buffer_drop_limit = 1024 * 8
var send_buffer: PackedByteArray = PackedByteArray()
var buffer: PackedByteArray = PackedByteArray()
var buf: PackedByteArray = PackedByteArray()
var position: int = 0;

func add_packet(packet: PackedByteArray) -> void:
    send_buffer.append_array(packet)
    if send_buffer.size() >= buffer_send_limit:
        post_packet()

func post_packet() -> void:
    if send_buffer.size() > 0:
        send_packet.emit(send_buffer)
        send_buffer = PackedByteArray()

func add_received_packet(packet: PackedByteArray) -> void:
    buffer.append_array(packet)

func check_drop() -> void:
    if position > buffer.size():
        push_error("EOF Reached")
        buffer = PackedByteArray()
        position = 0
        return
    if position > buffer_drop_limit:
        buffer = buffer.slice(position)
        position = 0

func seek(data_len: int) -> void:
    position = clamp(position + data_len, 0, buffer.size())

func flush() -> void:
    post_packet()

func close() -> void:
    post_packet()
    buffer = PackedByteArray()

func get_8() -> int:
    var value = buffer.decode_u8(position)
    position += 1
    check_drop()
    return value

func get_16() -> int:
    var value = buffer.decode_u16(position)
    position += 2
    check_drop()
    return value

func get_32() -> int:
    var value = buffer.decode_u32(position)
    position += 4
    check_drop()
    return value

func get_64() -> int:
    var value = buffer.decode_u64(position)
    position += 8
    check_drop()
    return value

func get_string() -> String:
    var length = get_32()
    buf = get_buffer(length)
    return buf.get_string_from_utf8()

func get_buffer(data_len: int) -> PackedByteArray:
    buf = self.buffer.slice(position, position + data_len)
    position += data_len
    check_drop()
    return buf

func get_float() -> float:
    var value = buffer.decode_float(position)
    position += 4
    check_drop()
    return value

func get_double() -> float:
    var value = buffer.decode_double(position)
    position += 8
    check_drop()
    return value

func get_var() -> Variant:
    var size = get_64()
    buf = get_buffer(size)
    return bytes_to_var_with_objects(buf)

func store_8(value: int) -> void:
    buf.resize(1)
    buf.encode_u8(0, value)
    add_packet(buf)

func store_16(value: int) -> void:
    buf.resize(2)
    buf.encode_u16(0, value)
    add_packet(buf)

func store_32(value: int) -> void:
    buf.resize(4)
    buf.encode_u32(0, value)
    add_packet(buf)

func store_64(value: int) -> void:
    buf.resize(8)
    buf.encode_u64(0, value)
    add_packet(buf)

func store_string(value: String) -> void:
    var buf2 = value.to_utf8_buffer()
    store_32(buf2.size())
    store_buffer(buf2)

func store_buffer(value: PackedByteArray) -> void:
    add_packet(value)

func store_float(value: float) -> void:
    buf.resize(4)
    buf.encode_float(0, value)
    add_packet(buf)

func store_double(value: float) -> void:
    buf.resize(4)
    buf.encode_double(0, value)
    add_packet(buf)

func store_var(value: Variant, full: bool = false) -> void:
    var buf2 = var_to_bytes_with_objects(value) if full else var_to_bytes(value)
    store_64(buf2.size())
    store_buffer(buf2)
