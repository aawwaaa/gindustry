extends Node

signal log_created(formatted: String, source: String, level: String, message: String);
signal progress_changed(new_progress: float, completed: int, total: int);

var log_levels = {
    "info" = "LogLevel_Info",
    "warn" = "LogLevel_Warn",
    "error" = "LogLevel_Error",
    "debug" = "LogLevel_Debug"
}

var enable_debug_log = false;
var log_access: FileAccess;

class Logger extends RefCounted:
    var source;
    var template;
    
    func _init(src: String):
        source = tr(src);
        self.template = "[{source}]\t[{level}] {message}" \
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

func register_log_source(source: String) -> Logger:
    return Logger.new(source);

func print_log(formatted: String, _1, _2, _3) -> void:
    print(formatted);
    log_access.store_string(formatted + "\n");

var completed_progress: int = 0;
var total_progress: int = 0;

func register_progress_source(total: int) -> Callable:
    total_progress += total;
    return func(increase: int):
        completed_progress += increase;
        @warning_ignore("integer_division")
        progress_changed.emit(completed_progress / total_progress, \
            completed_progress, total_progress);

func _ready() -> void:
    log_access = FileAccess.open("user://log_file.log", FileAccess.WRITE);
    log_created.connect(print_log);
    for level in log_levels:
        log_levels[level] = tr(log_levels[level])
