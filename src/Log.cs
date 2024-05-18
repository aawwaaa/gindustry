using Godot;
using System;
using System.Collections.Generic;

public partial class Log : Node
{
    public static readonly List<Logger> loggers = new List<Logger>();
    public static int longestLoggerNameLength = 0;

    public static readonly List<Progress> progresses = new List<Progress>();

    public delegate void LogListener(Logger logger, LogLevel level, string message);
    public static event LogListener OnLog;

    public delegate void ProgressListener(Progress progress);
    public static event ProgressListener OnProgressAdded;
    public static event ProgressListener OnProgressFinished;

    public delegate void ProgressChanged (Progress progress, int current, int total);
    public static event ProgressChanged OnProgressChanged;

    public delegate void TriggerListener();
    public static event TriggerListener OnProgressAllFinished;

    public static readonly StringName SINGLETON_NAME = "Log";

    public static Log Singleton
    {
        get
        {
            if (!Engine.HasSingleton(SINGLETON_NAME)) return null;
            return (Log)Engine.GetSingleton(SINGLETON_NAME);
        }
    }

    [Signal]
    public delegate void OnLogSignalEventHandler(Logger logger, LogLevel level, string message);
    [Signal]
    public delegate void OnProgressSignalAddedEventHandler(Progress progress);
    [Signal]
    public delegate void OnProgressFinishedSignalEventHandler(Progress progress);
    [Signal]
    public delegate void OnProgressChangedSignalEventHandler (Progress progress, int current, int total);
    [Signal]
    public delegate void OnProgressAllFinishedSignalEventHandler ();

    public Logger[] GetLoggers()
    {
        return loggers.ToArray();
    }

    public Progress[] GetProgresses()
    {
        return progresses.ToArray();
    }

    public partial class LogLevel: GodotObject
    {
        public static readonly List<LogLevel> values = new List<LogLevel>();

        public static readonly LogLevel Debug = new LogLevel("log_level_debug");
        public static readonly LogLevel Info = new LogLevel("log_level_info");
        public static readonly LogLevel Warning = new LogLevel("log_level_warning");
        public static readonly LogLevel Error = new LogLevel("log_level_error");

        public string name;
        private LogLevel(string name)
        {
            this.name = TranslationServer.Translate(name);
            values.Add(this);
            values.ForEach(level =>
            {
                if (level.name.Length < name.Length) level.name = level.name.PadRight(name.Length);
            });
        }
    }

    public partial class Logger: GodotObject
    {
        public string source;
        public string sourceTranslated;

        public Logger() : this("annonymous_log_source") { }
        public Logger(string source)
        {
            this.source = source;
            sourceTranslated = TranslationServer.Translate(source);
            sourceTranslated.PadRight(longestLoggerNameLength);
            loggers.Add(this);
            if (sourceTranslated.Length > longestLoggerNameLength)
            {
                longestLoggerNameLength = sourceTranslated.Length;
                loggers.ForEach(logger => 
                {
                    logger.sourceTranslated = logger.sourceTranslated.PadRight(longestLoggerNameLength);
                });
            }
        }

        public new void Free()
        {
            loggers.Remove(this);
            base.Free();
        }

        public void Log(LogLevel level, string message)
        {
            string formatted = $"[{sourceTranslated}] [{level.name}] {message}";
            GD.Print(formatted);
            if (OnLog != null) OnLog(this, level, formatted);
            if (Singleton != null) Singleton.EmitSignal("OnLogSignal", this, level, formatted);
        }

        public void Info(string message)
        {
            Log(LogLevel.Info, message);
        }

        public void Debug(string message)
        {
            Log(LogLevel.Debug, message);
        }

        public void Error(string message)
        {
            Log(LogLevel.Error, message);
        }

        public void Warning(string message)
        {
            Log(LogLevel.Warning, message);
        }
    }

    public partial class Progress: GodotObject
    {
        public string source;
        public string sourceTranslated;

        public string message;
        public string messageTranslated;

        public int total;
        public int current = 0;

        public event ProgressChanged OnProgressChanged;

        [Signal]
        public delegate void OnProgressChangedSignalEventHandler (Progress progress, int current, int total);

        public Progress(string source, string message, int total)
        {
            this.source = source;
            sourceTranslated = TranslationServer.Translate(source);
            this.total = total;
            progresses.Add(this);
            if(Log.OnProgressAdded != null) Log.OnProgressAdded(this);
            if (Singleton != null) Singleton.EmitSignal("OnProgressAddedSignal", this);

            SetMessage(message);
        }

        public void SetMessage(string message)
        {
            this.message = message;
            messageTranslated = TranslationServer.Translate(message);
            if (Log.OnProgressChanged != null) Log.OnProgressChanged(this, current, total);
            if (Singleton != null) Singleton.EmitSignal("OnProgressChangedSignal", this);
            if (OnProgressChanged != null) OnProgressChanged(this, current, total);
            EmitSignal("OnProgressChangedSignal", this, current, total);

        }

        public void AddProgress(int amount)
        {
            current += amount;
            if (current > total) current = total;
            if (Log.OnProgressChanged != null) Log.OnProgressChanged(this, current, total);
            if (Singleton != null) Singleton.EmitSignal("OnProgressChangedSignal", this);
            if (OnProgressChanged != null) OnProgressChanged(this, current, total);
            EmitSignal("OnProgressChangedSignal", this, current, total);
        }

        public void Finish()
        {
            current = total;
            progresses.Remove(this);
            if (Log.OnProgressFinished != null) Log.OnProgressFinished(this);
            if (Singleton != null) Singleton.EmitSignal("OnProgressFinishedSignal", this);
            if (OnProgressChanged != null) OnProgressChanged(this, current, total);
            EmitSignal("OnProgressChangedSignal", this, current, total);
            if (progresses.Count == 0 && Log.OnProgressAllFinished != null) Log.OnProgressAllFinished();
            if (Singleton != null) Singleton.EmitSignal("OnProgressAllFinishedSignal");
        }
    }

    public static Logger CreateLogger(string source)
    {
        return new Logger(source);
    }

    public static Progress CreateProgress(string source, string message, int total)
    {
        return new Progress(source, message, total);
    }
}
