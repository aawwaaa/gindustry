extends PanelContainer

static var progress_line_scene: PackedScene = load("res://ui/loading/progress_line.tscn")
static var log_line_scene: PackedScene = load("res://ui/loading/log_line.tscn")

@export var max_logs = 8;
var log_buffer: Array[Loading_LogLine] = [];
var progress_buffer: Dictionary = {};

func _ready() -> void:
    for child in %Logs.get_children():
        child.queue_free()
    for child in %Progresses.get_children():
        child.queue_free()
    Log.log_created.connect(add_log);
    Log.progress_tracker_created.connect(_on_log_progress_tracker_created)
    Log.progress_tracker_finished.connect(_on_log_progress_tracker_finished)

func add_log(_1, source: String, level: Log.LogLevel, message: String) -> void:
    var node = log_line_scene.instantiate()
    %Logs.add_child(node)
    node.apply(tr(source), level, message)
    log_buffer.append(node)
    if log_buffer.size() > max_logs:
        (log_buffer.pop_front() as Node).queue_free()

func _on_log_progress_tracker_created(tracker: Log.ProgressTracker) -> void:
    var line = progress_line_scene.instantiate()
    line.tracker = tracker
    %Progresses.add_child(line)
    progress_buffer[tracker] = line

func _on_log_progress_tracker_finished(tracker: Log.ProgressTracker) -> void:
    progress_buffer[tracker].queue_free()
    progress_buffer.erase(tracker)
