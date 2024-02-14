class_name PlayerController
extends Controller

const PLAYER_CONTROLLER_ATTRIBUTES = {"move": 1, "name": 1}

@export var player: Player;
var datas: Dictionary
var move_velocity: Vector2;

func _get_priority() -> int:
    return Controller.Prioritys.PLAYER;

func _get_attributes() -> Dictionary:
    return PLAYER_CONTROLLER_ATTRIBUTES;

func _get_move_velocity(_current_velocity: Vector2) -> Vector2:
    return move_velocity;

func _get_name() -> String:
    return player.player_name;

func _get_player_controller_type() -> String:
    return "controller"
