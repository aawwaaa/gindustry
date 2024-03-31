class_name PlayerController
extends Controller

const PLAYER_CONTROLLER_ATTRIBUTES = {"move": 1, "name": 1, "build": 1}

@export var player: Player;
var datas: Dictionary
var move_velocity: Vector2;

var build_plan: Array[BuildPlan] = []
var build_paused: bool = false

func _get_priority() -> int:
    return Controller.Prioritys.PLAYER;

func _get_attributes() -> Dictionary:
    return PLAYER_CONTROLLER_ATTRIBUTES;

func _get_move_velocity(_current_velocity: Vector2) -> Vector2:
    return move_velocity;

func _get_name() -> String:
    return player.player_name;

func _get_build_plan() -> Array[BuildPlan]:
    return build_plan

func _get_build_paused() -> bool:
    return build_paused

@rpc("authority", "call_remote", "reliable")
func add_build_plan_rpc(data: PackedByteArray, insert: bool) -> void:
    Global.temp.bas.load(data)
    var plan = BuildPlan.load_from(Global.temp.bas)
    if player != Game.current_player: plan.preview_name = ""
    if insert: build_plan.push_front(plan)
    else: build_plan.push_back(plan)
    Global.temp.bas.clear()

func add_build_plan(plan: BuildPlan, insert = false) -> void:
    plan.save_to(Global.temp.bas)
    var data = Global.temp.bas.submit()
    MultiplayerServer.rpc_sync(self, "add_build_plan_rpc", [data, insert])

@rpc("authority", "call_remote", "reliable")
func remove_build_plan_rpc(world: int, position: Vector2i) -> void:
    var target = null
    for plan in build_plan:
        if plan.world_id == world and plan.position == position:
            target = plan
    if target: build_plan.erase(target)

func remove_build_plan(plan: BuildPlan) -> void:
    MultiplayerServer.rpc_sync(self, "remove_build_plan_rpc", [plan.world_id, plan.position])
