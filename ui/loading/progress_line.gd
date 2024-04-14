extends VBoxContainer

@onready var name_label: Label = %Name
@onready var per_label: Label = %Per
@onready var progress_bar: ProgressBar = %ProgressBar

var tracker: Log.ProgressTracker;

func _ready() -> void:
    if not tracker: return
    tracker.updated.connect(_on_tracker_updated)
    _on_tracker_updated()

func _on_tracker_updated() -> void:
    name_label.text = "["+tr(tracker.source)+"] " + tr(tracker.name)
    var per = float(tracker.progress) / tracker.total
    per_label.text = str(round(per*100)) + "%"
    progress_bar.value = per
