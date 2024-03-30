class_name AdapterInterface
extends VBoxContainer

signal request_operation(operation: String, args: Array[Variant])
signal request_remote_operation(operation: String, args: Array[Variant])

var entity: Entity
var adapter: EntityAdapter:
    set = set_adapter
@export var adapter_name: String:
    get: return adapter.adapter_name if adapter else adapter_name
var remote_entity: bool = false
var interface_ready: bool = false

func _ready() -> void:
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    interface_ready = true

func _set_adapter(v: EntityAdapter, old: EntityAdapter) -> void:
    pass

func set_adapter(v: EntityAdapter) -> void:
    var old = adapter
    adapter = v
    _set_adapter(v, old)

func _load_interface() -> void:
    pass

func load_interface() -> void:
    adapter = entity.get_adapter(adapter_name) if adapter_name != "" else adapter
    _load_interface()

func operate_adapter(operation: String, args: Array[Variant] = []) -> void:
    var new_args = [adapter_name, operation]
    new_args.append_array(args)
    if remote_entity: request_remote_operation.emit("adapter", new_args)
    else: request_operation.emit("adapter", new_args)
