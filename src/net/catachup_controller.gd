class_name CatchupController
extends Node

signal finished()

var start_time: float
var duration: float
var counter: float

var started: bool = false

func mark_start() -> void:
    start_time = Time.get_ticks_msec() / 1000.0
    duration = 0.0
    counter = 0.0

func set_duration(dur: float) -> void:
    duration = dur

func start() -> void:
    # TODO auto time scale
    Engine.time_scale = 10000
    Engine.max_fps = 6
    Engine.physics_ticks_per_second = 600000
    Engine.max_physics_steps_per_frame = 8000
    started = true

func stop() -> void:
    Engine.time_scale = 1
    Engine.max_fps = ProjectSettings.get_setting("application/run/max_fps")
    Engine.physics_ticks_per_second = 60
    Engine.max_physics_steps_per_frame = 8
    started = false

func _physics_process(delta: float) -> void:
    if not started: return
    counter += delta
    if counter >= duration:
        stop()
        finished.emit()
