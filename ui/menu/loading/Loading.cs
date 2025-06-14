using Godot;
using System;

namespace builtin.ui;

public partial class Loading : Control
{
    [Export]
    public PackedScene progressScene;

    public Label logs;
    public int logRows = 0;
    public VBoxContainer progress;

    public override void _Ready()
    {
        logs = GetNode<Label>("%Logs");
        progress = GetNode<VBoxContainer>("%Progress");
        global::Log.LogCreated += Log;
        logRows = 0;
        global::Log.ProgressTrackerCreated += ProgressTrackerCreated;
    }

    public void Log(string formatted, string _1, string _2, string _3)
    {
        logRows += 1;
        if (logRows > 10)
        {
            logs.Text = logs.Text[(logs.Text.IndexOf('\n')+1)..];
            logRows = 10;
        }
        logs.Text += "\n" + formatted;
    }

    public void ProgressTrackerCreated(global::Log.ProgressTracker tracker)
    {
        LoadingProgress progress = progressScene.Instantiate<LoadingProgress>();
        progress.tracker = tracker;
        this.progress.AddChild(progress);
    }
}
