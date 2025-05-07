using Godot;
using System;
using System.IO;
using System.Collections.Generic;

public partial class Log: Node
{
    public static Log Instance { get; private set; }

    [Signal]
    public delegate void log_createdEventHandler(string formatted, string source, string level, string message);
    [Signal]
    public delegate void progress_tracker_createdEventHandler(ProgressTracker tracker);
    [Signal]
    public delegate void progress_tracker_finishedEventHandler(ProgressTracker tracker);
    [Signal]
    public delegate void all_progress_tracker_finishedEventHandler();

    public static event Log.log_createdEventHandler LogCreated;
    public static event Log.progress_tracker_createdEventHandler ProgressTrackerCreated;
    public static event Log.progress_tracker_finishedEventHandler ProgressTrackerFinished;
    public static event Log.all_progress_tracker_finishedEventHandler AllProgressTrackerFinished;

    public enum LogLevel { Debug = 0, Info = 1, Warn = 2, Error = 3 }

    public static readonly string[] LogLevels = { "Debug", "Info ", "Warn ", "Error" };

    public static bool EnableDebugLog { get { return OS.HasFeature("debug"); } }
    public Godot.FileAccess logAccess;

    public List<ProgressTracker> activeProgressTrackers = new();
    public static List<ProgressTracker> ActiveProgressTrackers => Instance.activeProgressTrackers;

    public partial class Logger: RefCounted
    {
        public string source;
        public string template;

        public Logger(string source)
        {
            this.source = source;
            source = source.PadRight(8, ' ');
            this.template = $"[{source}]\t[{{level}}]\t{{message}}";
        }
        
        public void Log(LogLevel level, string message)
        {
            if (level == LogLevel.Debug && !EnableDebugLog) return;
            var formatted = template
                .Replace("{level}", LogLevels[(int)level])
                .Replace("{message}", message);
            Instance.EmitSignal(global::Log.SignalName.log_created,
                formatted, source, LogLevels[(int)level], message);
        }

        public void Info(string message)
        {
            Log(LogLevel.Info, message);
        }

        public void Warn(string message)
        {
            Log(LogLevel.Warn, message);
        }

        public void Error(string message)
        {
            Log(LogLevel.Error, message);
        }

        public void Debug(string message)
        {
            Log(LogLevel.Debug, message);
        }
    }

    public partial class ProgressTracker: RefCounted
    {
        private string name = "";
        private int progress = 0;
        private int total = 0;

        public string Name { get { return name; } set { name = value; EmitSignal(SignalName.Updated); } }
        public int Progress { get { return progress; } set { progress = value; EmitSignal(SignalName.Updated); } }
        public int Total { get { return total; } set { total = value; EmitSignal(SignalName.Updated); } }

        public string source;

        [Signal]
        public delegate void UpdatedEventHandler();

        public ProgressTracker(int total, string name, string source)
        {
            this.total = total;
            this.name = Tr(name);
            this.source = Tr(source);
            this.Progress = 0;
            
            Instance.activeProgressTrackers.Add(this);
            Instance.EmitSignal(global::Log.SignalName.progress_tracker_created, this);
        }

        public void Finish()
        {
            Instance.EmitSignal(global::Log.SignalName.progress_tracker_finished, this);
            Instance.activeProgressTrackers.Remove(this);
            if (Instance.activeProgressTrackers.Count == 0)
                Instance.EmitSignal(global::Log.SignalName.all_progress_tracker_finished);
        }
    }

    public Logger register_logger(string source)
    {
        return new Logger(source);
    }

    public static Logger RegisterLogger(string source) => new Logger(source);

    public void PrintLog(string formatted, string _1, string _2, string _3)
    {
        GD.Print(formatted);
        logAccess?.StoreString(formatted + "\n");
    }

    public ProgressTracker register_progress_tracker(int total, string name, string source)
    {
        return new ProgressTracker(total, name, source);
    }

    public static ProgressTracker RegisterProgressTracker(int total, string name, string source) => Instance.register_progress_tracker(total, name, source);

    public Log()
    {
        Instance = this;
    }

    public override void _Ready()
    {
        logAccess = Godot.FileAccess.Open("user://log_file.log", Godot.FileAccess.ModeFlags.Write);
        LogCreated += PrintLog;

        log_created += (formatted, source, level, message) => LogCreated?.Invoke(formatted, source, level, message);
        progress_tracker_created += (tracker) => ProgressTrackerCreated?.Invoke(tracker);
        progress_tracker_finished += (tracker) => ProgressTrackerFinished?.Invoke(tracker);
        all_progress_tracker_finished += () => AllProgressTrackerFinished?.Invoke();
    }
}
