using Godot;
using System.Collections.Generic;
using System;

public interface GDScriptAdapter
{

}


public partial class GDScriptAdapterImplement: GodotObject
{
    public static readonly Dictionary<StringName, Spawner> AdapterSpawners = new();
    public delegate GDScriptAdapter Spawner();

    public GDScriptAdapter Create(StringName name)
    {
        if (!AdapterSpawners.TryGetValue(name, out var spawner))
            return null;
        return spawner();
    }
}
