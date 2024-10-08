class_name ByteArrayStream
extends Stream

var array: PackedByteArray;
var position: int = 0;

func _init(arr: PackedByteArray): self.array = arr;

func seek(data_len: int) -> void: position += data_len;

func get_n(len: int = 1) -> int:
    var data: int;
    match len:
        1: data = array.decode_u8(position)
        2: data = array.decode_u16(position)
        4: data = array.decode_u32(position)
        8: data = array.decode_u64(position)
    position += len
    return data

func get_8() -> int: return get_n(1);
func get_16() -> int: return get_n(2);
func get_32() -> int: return get_n(4);
func get_64() -> int: return get_n(8);
func get_string() -> String:
    var len: int = get_32();
    var buffer = get_buffer(len);
    return buffer.get_string_from_utf8()
func get_buffer(data_len: int) -> PackedByteArray:
    var buffer = array.slice(position, position + data_len)
    position += data_len
    return buffer
func get_float() -> float:
    var data: float = array.decode_float(position)
    position += 4
    return data
func get_double() -> float: 
    var data: float = array.decode_double(position)
    position += 8
    return data
func get_var() -> Variant: 
    var size = get_64()
    var data = array.slice(position, position + size)
    position += size
    return bytes_to_var_with_objects(data)

func append_at_position(size: int) -> void:
    if array.size() >= position + size: return
    array.resize(position + size)

func store_n(size: int, value: int) -> void:
    append_at_position(size)
    match size:
        1: array.encode_u8(position, value)
        2: array.encode_u16(position, value)
        4: array.encode_u32(position, value)
        8: array.encode_u64(position, value)
    position += size

func store_8(value: int) -> void: store_n(1, value);
func store_16(value: int) -> void: store_n(2, value);
func store_32(value: int) -> void: store_n(4, value);
func store_64(value: int) -> void: store_n(8, value);
func store_string(value: String) -> void:
    var buffer = value.to_utf8_buffer()
    store_32(buffer.size())
    store_buffer(buffer)
func store_buffer(value: PackedByteArray) -> void:
    array.append_array(value)
    position += value.size()
func store_float(value: float) -> void:
    append_at_position(4)
    array.encode_float(position, value)
    position += 4
func store_double(value: float) -> void:
    append_at_position(8)
    array.encode_double(position, value)
    position += 8
func store_var(value: Variant, full: bool = false) -> void:
    var buffer = var_to_bytes_with_objects(value) if full else var_to_bytes(value)
    store_64(buffer.size())
    append_at_position(buffer.size())
    array.append_array(buffer)
    position += buffer.size()
