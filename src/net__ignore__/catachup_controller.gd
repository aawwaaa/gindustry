class_name CatchupController
extends Node

signal finished()

const TIME_SCALE = 15

var start_time: float
var duration: float
var counter: float

var auto_stop = true
var started: bool = false
var progress: Log.ProgressTracker = null

var sync_queue: Array[PeerData.ClientSyncPack]:
    get: return Vars.client.sync_queue

func mark_start() -> void:
    start_time = Time.get_ticks_msec() / 1000.0
    duration = 0.0
    counter = 0.0

func set_duration(dur: float) -> void:
    duration = dur

func start() -> void:
    if progress: progress.finish()
    set_scale(TIME_SCALE)
    started = true
    progress = Log.register_progress_tracker(0, "Client_Catchup", Vars.client.logger.source)

func set_scale(scale: float) -> void:
    if scale < 1: scale = 1
    Engine.time_scale = scale
    Engine.physics_ticks_per_second = int(60 * scale)
    Engine.max_physics_steps_per_frame = int(2 * scale)

func stop() -> void:
    if not started: return
    Engine.time_scale = 1
    Engine.max_fps = ProjectSettings.get_setting("application/run/max_fps")
    Engine.physics_ticks_per_second = 60
    Engine.max_physics_steps_per_frame = 8
    started = false
    if progress:
        progress.finish()
        progress = null

func _process(_delta: float) -> void:
    if progress:
        progress.total = round(duration * TIME_SCALE)
        progress.progress = round(counter * TIME_SCALE)

func _physics_process(delta: float) -> void:
    if not started: return
    counter += delta
    var removes = []
    for packet in sync_queue:
        if packet.time > counter: break
        packet.run()
        removes.append(packet)
    for packet in removes:
        sync_queue.erase(packet)
    if counter >= duration:
        if auto_stop: stop()
        finished.emit()

