class_name Controller
extends Node

signal target_changed(target: ControllerAdapter, from: ControllerAdapter)

enum Prioritys{
    DEFAULT = 0,
    PLAYER = 1024,
    CARRIER = 2048
}

static var adapter_targets: Dictionary = {}
const EMPTY_DICT = {};

var target_id: int;
var target: ControllerAdapter:
    set(v):
        var old = target if target else null
        target = v
        target_changed.emit(v, old)

var entity: Entity:
    get: return target.entity_node if target else null;

static func _on_game_signal_reset_game() -> void:
    adapter_targets = {};

func load_target() -> void:
    if target_id == 0: return
    if not adapter_targets.has(target_id):
        adapter_targets[target_id] = []
    if adapter_targets[target_id] is ControllerAdapter:
        adapter_targets[target_id].add_controller(self)
    elif adapter_targets[target_id] is Array:
        adapter_targets[target_id].append(self)

func accept_adapter(new_target: ControllerAdapter) -> void:
    self.target = new_target;
    self.target_id = target.get_adapter_id();

func _exit_tree() -> void:
    if is_instance_valid(target) and target:
        target.remove_controller(self)

func get_target_attribute(key: String) -> Variant:
    if not target:
        return null
    return target.get_attribute(key)

@rpc("authority", "call_remote", "reliable")
func operate_target_rpc(operation: String, args: Array[Variant] = []) -> void:
    target.operate(self, operation, args)

@rpc("authority", "call_remote", "reliable")
func request_access_target_rpc(target: Node2D) -> bool:
    return self.target.entity_node.request_access_target(target)

@rpc("authority", "call_remote", "reliable")
func clear_access_target_rpc() -> void:
    target.entity_node.clear_access_target()

@rpc("authority", "call_remote", "reliable")
func operate_remote_target_rpc(operation: String, args: Array[Variant] = []) -> bool:
    return target.operate_remote(self, operation, args)

func operate_target(operation: String, args: Array[Variant] = []) -> void:
    MultiplayerServer.rpc_sync(self, "operate_target_rpc", [operation, args])

func request_access_target(target: Node2D) -> void:
    MultiplayerServer.rpc_sync(self, "request_access_target_rpc", [target])

func clear_access_target() -> void:
    MultiplayerServer.rpc_sync(self, "clear_access_target_rpc")

func operate_remote_target(operation: String, args: Array[Variant] = []) -> void:
    MultiplayerServer.rpc_sync(self, "operate_remote_target_rpc", [operation, args])

@rpc("authority", "call_remote", "reliable")
func control_to_rpc(target: ControllerAdapter):
    if target:
        target.remove_controller(self)
    target.add_controller(self)

func control_to(target: ControllerAdapter) -> void:
    MultiplayerServer.rpc_sync(self, "control_to_rpc", [target])

@rpc("authority", "call_remote", "reliable")
func control_to_id_rpc(target_id: int) -> void:
    if target:
        target.remove_controller(self)
    self.target_id = target_id
    target = null
    load_target()

func control_to_id(target_id: int) -> void:
    MultiplayerServer.rpc_sync(self, "control_to_id_rpc", [target_id])

func _get_priority() -> int:
    return Prioritys.DEFAULT;

func _get_attributes() -> Dictionary:
    return EMPTY_DICT;

func _get_move_velocity(_current_velocity: Vector2) -> Vector2:
    return Vector2.ZERO;

func _get_name() -> String:
    return "";

func _get_build_plan() -> Array[BuildPlan]:
    return []

func _get_build_paused() -> bool:
    return false

const current_data_version = 0;

func load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return;
    if target:
        target.remove_controller(self)
        target = null
    target_id = stream.get_64();
    load_target();

func save_data(stream: Stream) -> void:
    stream.store_16(current_data_version);
    # version 0
    stream.store_64(target_id)
    
