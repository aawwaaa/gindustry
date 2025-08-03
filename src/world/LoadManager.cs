using Godot;
using System;
using System.Collections.Generic;

namespace Gindustry.World;

[GlobalClass]
public partial class LoadManager: GodotObject
{
    public Dimension Dimension;
    public HashSet<LoadController> Controllers = new();
    public Dictionary<int, LayerLoadManager> Managers = new();

    public LoadManager(Dimension dimension)
    {
        Dimension = dimension;
    }

    public void Create()
    {
        Vars.Game.SaveDataLayer.CreateLoadManager(this);
    }

    public void Destroy()
    {
        foreach(var manager in Managers.Values)
        {
            manager.Destroy();
        }
        Managers.Clear();
        Controllers.Clear();
    }
}
