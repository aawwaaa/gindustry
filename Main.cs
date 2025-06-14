using Godot;
using System;

public partial class Main : Node
{
    public Log.Logger logger = Log.RegisterLogger("Main");
    public override async void _Ready()
    {
        Vars.Main = this;
        Vars.Core.StateChangedGeneric += (state, from)
            => logger.Info("State change: " + from.ToString() + " -> " + state.ToString());
        await Vars.Core.StartLoad();
        logger.Info("Load finish!");
    }
}
