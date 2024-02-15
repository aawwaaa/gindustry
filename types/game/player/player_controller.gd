class_name PlayerController
extends Controller

const PLAYER_CONTROLLER_ATTRIBUTES = {"move": 1, "name": 1, "build": 1}

@export var player: Player;
var datas: Dictionary
var move_velocity: Vector2;

var build_paused: bool = false
var build_plan: Array[BuildPlan] = []

func _get_priority() -> int:
    return Controller.Prioritys.PLAYER;

func _get_attributes() -> Dictionary:
    return PLAYER_CONTROLLER_ATTRIBUTES;

func _get_move_velocity(_current_velocity: Vector2) -> Vector2:
    return move_velocity;

func _get_name() -> String:
    return player.player_name;

func _get_build_plan() -> Array[BuildPlan]:
    return build_plan if not build_paused else []
