class_name PlayerController
extends Controller

const SYNC_PERIOD = 0.05

class PlayerMovementModule extends ControllerModule:
    var synced_move_velocity: Vector3
    var synced_roll_velocity: Vector3

    var input_move_velocity: Vector3
    var input_roll_velocity: Vector3

    var counter: float = 0

    func _physics_process(delta: float) -> void:
        if not is_multiplayer_authority(): return
        counter += delta
        if counter < SYNC_PERIOD: return
        counter = 0

        var dict = {
            "move_velocity": input_move_velocity,
            "roll_velocity": input_roll_velocity
        }
        sync_data(dict)

    @rpc("authority", "call_remote", "reliable")
    func sync_data(dict: Dictionary) -> void:
        if Vars.client.post_to_server(self, "sync_data", [dict]): return
        sync("sync_data_rpc", [dict])

    func sync_data_rpc(dict: Dictionary) -> void:
        synced_move_velocity = dict["move_velocity"]
        synced_roll_velocity = dict["roll_velocity"]

    func _get_move_velocity() -> Vector3:
        return Vector3.ZERO
    func _get_roll_velocity() -> Vector3:
        return Vector3.ZERO

var movement: PlayerMovementModule

func _ready() -> void:
    movement = PlayerMovementModule.new()
    add_module(movement)
