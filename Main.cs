using Gindustry;
using Godot;
using System;

namespace Gindustry;

public partial class Main : Node
{
    public Log.Logger logger = Log.RegisterLogger("Main");
    public override void _Ready()
    {
        Vars.Main = this;
        Vars.Core.StateChangedGeneric += (state, from)
            => logger.Info("State change: " + from.ToString() + " -> " + state.ToString());
        var task = Vars.Core.StartLoad();
        task.ContinueWith(t => {
            logger.Info("Load finish!");
        });
    }
}
