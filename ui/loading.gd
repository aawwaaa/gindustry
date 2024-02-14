extends PanelContainer

@export var max_logs = 8;
var log_buffer: Array = [];

func _ready() -> void:
    Log.log_created.connect(add_log);
    %LoadingLog.text = "";
    
    Log.progress_changed.connect(progress_changed);

func add_log(formatted: String, _1, _2, _3) -> void:
    log_buffer.append(formatted);
    if log_buffer.size() >= max_logs:
        log_buffer.pop_front();
    %LoadingLog.text = "";
    for log_message in log_buffer:
        %LoadingLog.text += log_message + "\n";
    pass

func progress_changed(_1, part: int, total: int) -> void:
    %ProgressBar.max_value = total;
    %ProgressBar.value = part;
