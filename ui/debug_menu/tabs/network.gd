class_name DebugMenu_Network
extends VBoxContainer

var menu: DebugMenu

@onready var duration: LineEdit = %Duration
@onready var catchup_progress: ProgressBar = %CatchupProgress
@onready var catchup_status: Label = %CatchupStatus

var last_physics_frame: int = 0
var last_time: float = 0
var physics_delta: float = 0
var last_physics_time = 0

func _process(_delta: float) -> void:
    var delta = Time.get_ticks_usec() / 1000000.0 - last_time
    var controller = Vars.client.catchup_controller
    catchup_progress.value = controller.counter / controller.duration if controller.started else 0
    catchup_status.text = "Process: {fps} {delta}\nPhysics: {pfps} {physics_delta} {acdelta}".format({
        fps = Engine.get_frames_per_second(),
        delta = round(delta * 100000) / 100000.0,
        pfps = round((Engine.get_physics_frames() - last_physics_frame) / delta * 100) / 100.0,
        physics_delta = round(physics_delta * 100000) / 100000.0,
        acdelta = round(get_physics_process_delta_time() * 100000) / 100000.0
    })
    last_time = Time.get_ticks_usec() / 1000000.0
    last_physics_frame = Engine.get_physics_frames()

func _physics_process(_delta: float) -> void:
    var delta = Time.get_ticks_usec() / 1000000.0 - last_physics_time
    physics_delta = delta
    last_physics_time = Time.get_ticks_usec() / 1000000.0

func _on_start_pressed() -> void:
    Vars.client.catchup_controller.start()

func _on_set_duration_pressed() -> void:
    Vars.client.catchup_controller.set_duration(float(duration.text))

func _on_mark_start_pressed() -> void:
    Vars.client.catchup_controller.mark_start()

