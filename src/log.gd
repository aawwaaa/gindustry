extends Node

signal log_created(formatted: String, source: String, level: String, message: String);
signal progress_tracker_created(tracker: ProgressTracker);
signal progress_tracker_finished(tracker: ProgressTracker);
signal all_progress_tracker_finished();

var log_levels = {
    "info" = "LogLevel_Info",
    "warn" = "LogLevel_Warn",
    "error" = "LogLevel_Error",
    "debug" = "LogLevel_Debug"
}

var enable_debug_log = false;
var log_access: FileAccess;

var active_progress_trackers: Array[ProgressTracker] = []

class Logger extends RefCounted:
    var source: String;
    var template: String;
    
    func _init(src: String):
        source = tr(src);
        self.template = "[{source}]\t[{level}]\t{message}" \
            .format({source = tr(source)});
    
    func log(level: String, message: String):
        var formatted = template.format({level = \
            Log.log_levels[level], \
            message = message})
        if level != "debug" or Log.enable_debug_log:
            Log.log_created.emit(formatted, \
            source, level, message);
    
    func info(message: String):
        self.log("info", message);
    
    func warn(message: String):
        self.log("warn", message);
    
    func error(message: String):
        self.log("error", message);
    
    func debug(message: String):
        self.log("debug", message);

class ProgressTracker extends RefCounted:
    var name: String:
        set(v): name = v; updated.emit()
    var source: String
    var progress: int:
        set(v): progress = v; updated.emit()
    var total: int

    signal updated()

    func _init(t: int, n: String, src: String) -> void:
        self.name = n
        self.source = src
        self.total = t
        self.progress = 0
        Log.active_progress_trackers.append(self)
        Log.progress_tracker_created.emit(self)
    
    func finish() -> void:
        Log.progress_tracker_finished.emit(self)
        Log.active_progress_trackers.erase(self)
        if Log.active_progress_trackers.is_empty():
            Log.all_progress_tracker_finished.emit()

func register_logger(source: String) -> Logger:
    return Logger.new(source);

func print_log(formatted: String, _1, _2, _3) -> void:
    print(formatted);
    log_access.store_string(formatted + "\n");

func register_progress_tracker(total: int, n: String, source: String) -> ProgressTracker:
    return ProgressTracker.new(total, n, source)

func _ready() -> void:
    log_access = FileAccess.open("user://log_file.log", FileAccess.WRITE);
    log_created.connect(print_log);
    for level in log_levels:
        log_levels[level] = tr(log_levels[level])
