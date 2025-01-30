using Godot;
using System.Collections.Generic;
using System;

namespace Gen {};

public interface GDScriptAdapter
{
    public bool IsOverriden {get; set;}
    public void _SetAdapter(GodotObject adapter);
}

[GodotClassName("GA")]
public partial class GA: Node
{
    public static readonly Dictionary<StringName, Spawner> AdapterSpawners = new();
    public delegate GDScriptAdapter Spawner();

    public GodotObject Create(StringName name)
    {
        if (!AdapterSpawners.TryGetValue(name, out var spawner))
            return null;
        return (GodotObject)spawner();
    }

    public partial void LoadStatics();

    public GodotObject u(GodotObject data)
    {
        if (data.HasMethod("_get_instance"))
            return (GodotObject)data.Call("_get_instance");

        return data;
    }

    public void SetAdapter(GodotObject input, GodotObject adapter)
    {
        if (input is GDScriptAdapter ad)
        {
            ad._SetAdapter(adapter);
        }
    }

    public void HaventOverriden(GodotObject input)
    {
        if (input is GDScriptAdapter ad)
        {
            ad.IsOverriden = false;
        }
    }

    public String TryCatch(Callable callable)
    {
        try
        {
            callable.Call();
            return null;
        }
        catch (Exception e)
        {
            return e.ToString();
        }
    }

    public void Throw(Vaiant obj)
    {
        throw obj;
    }
}
