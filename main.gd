extends Object

func _ready() -> void:
    Log.CreateLogger("123").Info(Vars.Objects)
    for source in Log.GetLoggers():
        source.Info(source.sourceTranslated)
