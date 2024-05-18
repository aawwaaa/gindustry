using Godot;
using System;

public partial class Main : Node
{
    public static Log.Logger logger = new Log.Logger("main_log_source");

    public override void _Ready()
    {
        logger.Info("Hello world");
    }
}
