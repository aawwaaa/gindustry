class_name PlayerData
extends Node

var player_data_type: String
var player: Player

var has_private_data: bool 

func _init_data() -> void:
    pass

func _init_private_data() -> void:
    pass

func _load_data(_stream: Stream) -> void:
    pass

func _save_data(_stream: Stream) -> void:
    pass

func _load_private_data(_stream: Stream) -> void:
    pass

func _save_private_data(_stream: Stream) -> void:
    pass

func _apply_data() -> void:
    pass

func _apply_private_data() -> void:
    pass
