class_name Stream
extends RefCounted

func seek(_len: int) -> void: return;
func flush() -> void: return;
func close() -> void: return;

func get_error() -> Error: return OK;

func get_8() -> int: return 0;
func get_16() -> int: return 0;
func get_32() -> int: return 0;
func get_64() -> int: return 0;
func get_string() -> String:
    var length = get_32();
    var buffer = get_buffer(length)
    return buffer.get_string_from_utf8()
func get_buffer(_len: int) -> PackedByteArray: return [];
func get_float() -> float: return 0.0;
func get_double() -> float: return 0.0;
func get_var() -> Variant:
    var size = get_64()
    var buffer = get_buffer(size)
    return bytes_to_var_with_objects(buffer)

func store_8(_value: int) -> void: return;
func store_16(_value: int) -> void: return;
func store_32(_value: int) -> void: return;
func store_64(_value: int) -> void: return;
func store_string(_value: String) -> void:
    var buffer = _value.to_utf8_buffer()
    store_32(buffer.size())
    store_buffer(buffer)
func store_buffer(_value: PackedByteArray) -> void: return;
func store_float(_value: float) -> void: return;
func store_double(_value: float) -> void: return;
func store_var(value: Variant, full: bool = false) -> void:
    var buffer = var_to_bytes_with_objects(value) if full else var_to_bytes(value)
    store_64(buffer.size())
    store_buffer(buffer)
