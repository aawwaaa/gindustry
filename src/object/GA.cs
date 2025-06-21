using Godot;
using System.Collections.Generic;
using System;

namespace Gindustry.Object;

public interface GDScriptAdapter
{
}

[GodotClassName("GA")]
public partial class GA: Node
{
    public static readonly Dictionary<StringName, Spawner> AdapterSpawners = new();
    public static GA Instance {get; private set;}
    public delegate GDScriptAdapter Spawner(Godot.Collections.Array args);

    public GodotObject Create(StringName name, Godot.Collections.Array args)
    {
        if (!AdapterSpawners.TryGetValue(name, out var spawner))
            return null;
        return (GodotObject)spawner(args);
    }

    public override void _Ready()
    {
        Instance = this;
    }

    public partial void LoadStatics();

    public static T U<T>(GodotObject data) where T: GodotObject
    {
        if (data.HasMethod("inst"))
            return (T)data.Call("inst");

        return (T)data;
    }
    public T u<T>(GodotObject data) where T: GodotObject
    {
        return U<T>(data);
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

    public void Throw(Variant obj)
    {
        throw new Exception(obj.ToString());
    }
}
