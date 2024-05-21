using Godot;
using System;
using System.Threading.Tasks;

public partial class Main : Node
{
    public static Log.Logger logger = new Log.Logger("main-log-source");

    public override void _Ready()
    {
        logger.Info("Hello world");

        GDScript script = GD.Load<GDScript>("res://main.gd");
        GodotObject result = (GodotObject)script.New();
        result.Call("_ready"); 

        Vars.core.StartLoad();
        Vars.game.InitGame();
    }
}
