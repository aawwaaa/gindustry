class_name Stream
extends RefCounted

func seek(_len: int) -> void: return;

func get_8() -> int: return 0;
func get_16() -> int: return 0;
func get_32() -> int: return 0;
func get_64() -> int: return 0;
func get_string() -> String: return "";
func get_buffer(_len: int) -> PackedByteArray: return [];
func get_float() -> float: return 0.0;
func get_double() -> float: return 0.0;
func get_var() -> Variant: return null;

func store_8(_value: int) -> void: return;
func store_16(_value: int) -> void: return;
func store_32(_value: int) -> void: return;
func store_64(_value: int) -> void: return;
func store_string(_value: String) -> void: return;
func store_buffer(_value: PackedByteArray) -> void: return;
func store_float(_value: float) -> void: return;
func store_double(_value: float) -> void: return;
func store_var(_value: Variant, _full: bool = false) -> void: return;
