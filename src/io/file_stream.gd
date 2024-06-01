class_name FileStream
extends Stream

var access: FileAccess;

func _init(acc: FileAccess): self.access = acc;

func seek(data_len: int) -> void: access.seek(data_len + access.get_position());
func flush() -> void: access.flush();
func close() -> void: access.close();

func get_error() -> Error: return access.get_error();

func get_8() -> int: return access.get_8();
func get_16() -> int: return access.get_16();
func get_32() -> int: return access.get_32();
func get_64() -> int: return access.get_64();
func get_string() -> String:
    var length = access.get_32();
    var buffer = get_buffer(length)
    return buffer.get_string_from_utf8()
func get_buffer(data_len: int) -> PackedByteArray: return access.get_buffer(data_len);
func get_float() -> float: return access.get_float();
func get_double() -> float: return access.get_double();
func get_var() -> Variant:
    var size = get_64()
    var buffer = get_buffer(size)
    return bytes_to_var_with_objects(buffer)

func store_8(value: int) -> void: access.store_8(value);
func store_16(value: int) -> void: access.store_16(value);
func store_32(value: int) -> void: access.store_32(value);
func store_64(value: int) -> void: access.store_64(value);
func store_string(value: String) -> void:
    var buffer = value.to_utf8_buffer()
    access.store_32(buffer.size())
    access.store_buffer(buffer)
func store_buffer(value: PackedByteArray) -> void: access.store_buffer(value);
func store_float(value: float) -> void: access.store_float(value);
func store_double(value: float) -> void: access.store_double(value);
func store_var(value: Variant, full: bool = false) -> void:
    var buffer = var_to_bytes_with_objects(value) if full else var_to_bytes(value)
    access.store_64(buffer.size())
    access.store_buffer(buffer)
