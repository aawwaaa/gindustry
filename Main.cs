using Godot;
using System;

public partial class Main : Node
{
    public Log.Logger logger = Log.RegisterLogger("Main");
    public override void _Ready()
    {
        Vars.Instance.Init();
        Vars.Core.StateChangedGeneric += (state, from)
            => logger.Info("State change: " + from.ToString() + " -> " + state.ToString());
        Vars.Core.StartLoad();
        logger.Info("Load finish!");
    }
}
