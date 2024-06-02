class_name ByteArrayStream
extends Stream

var array: PackedByteArray;
var position: int = 0;

func _init(arr: PackedByteArray): self.array = arr;

func clear() -> void:
    array = PackedByteArray()
    position = 0

func submit() -> PackedByteArray:
    var data = array.slice(0, position)
    clear()
    return data

func load(data: PackedByteArray) -> void:
    array = data
    position = 0

func seek(data_len: int) -> void: position += data_len;

func get_n(length: int = 1) -> int:
    var data: int;
    match length:
        1: data = array.decode_u8(position)
        2: data = array.decode_u16(position)
        4: data = array.decode_u32(position)
        8: data = array.decode_u64(position)
    position += length
    return data

func get_error() -> Error: return ERR_FILE_EOF if position > array.size() else OK;

func get_8() -> int: return get_n(1);
func get_16() -> int: return get_n(2);
func get_32() -> int: return get_n(4);
func get_64() -> int: return get_n(8);
func get_string() -> String:
    var length: int = get_32();
    var buffer = get_buffer(length);
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
    array.append_array(buffer)
    position += buffer.size()
