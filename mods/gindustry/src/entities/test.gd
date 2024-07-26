extends Entity

func _entity_init() -> void:
    super._entity_init()

func _entity_deinit() -> void:
    super._entity_deinit()

func _load_data(stream: Stream) -> Error:
    var err = super._load_data(stream)
    if err: return err
    return Utils.load_data_with_version(stream, [])

func _save_data(stream: Stream) -> void:
    super._save_data(stream)
    Utils.save_data_with_version(stream, [])
