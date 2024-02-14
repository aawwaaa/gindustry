extends PlayerData

var last_control_target: int

func _init_data() -> void:
    pass

func _init_private_data() -> void:
    pass

const current_data_version = 0

func _load_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return

func _save_data(stream: Stream) -> void:
    stream.store_16(current_data_version)
    # version 0

const current_private_data_version = 0

func _load_private_data(stream: Stream) -> void:
    var version = stream.get_16();
    # version 0
    if version < 0: return
    last_control_target = stream.get_64()

func _save_private_data(stream: Stream) -> void:
    stream.store_16(current_private_data_version)
    # version 0
    stream.store_64(player.get_controller().target_id)

func _apply_private_data() -> void:
    player.get_controller().control_to_id(last_control_target)
