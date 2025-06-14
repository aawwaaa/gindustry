using Godot;
using System;

namespace builtin.ui;

public partial class LoadingProgress : VBoxContainer
{
    public Log.ProgressTracker tracker;

    public Label source;
    public Label message;
    public Label progress;
    public ProgressBar progressBar;

    public override void _Ready()
    {
        source = GetNode<Label>("%Source");
        message = GetNode<Label>("%Message");
        progress = GetNode<Label>("%Progress");
        progressBar = GetNode<ProgressBar>("%ProgressBar");
        tracker.Updated += Update;
        Update();
        tracker.Finished += QueueFree;
    }
    
    public void Update()
    {
        source.Text = tracker.source;
        message.Text = tracker.Name;
        double precent = tracker.Total == 0? 1: 
            (double)tracker.Progress / tracker.Total;
        progress.Text = Math.Round(precent * 100).ToString() + "%";
        progressBar.Value = precent;
    }
}
