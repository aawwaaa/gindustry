using Godot;
using System;
using System.Collections.Generic;

public static class Vars
{
    public static readonly StringName singletonName = new StringName("Vars");
    public static Node Instance{ get {
        return (Node)Engine.GetSingleton(singletonName);
    } }

    private static Dictionary<String, GodotObject> cache = new Dictionary<String, GodotObject>();
    private static T Get<T>(String name) where T : GodotObject
    {
        if (cache.ContainsKey(name)) return (T)cache[name];
        GodotObject obj = (GodotObject)Instance.Get(new StringName(name));
        if (obj == null) return null;
        cache[name] = obj;
        return (T)obj;
    }

    public static Node main{ get { return Get<Node>("main"); }}
    public static SceneTree tree{ get { return Get<SceneTree>("tree"); }}

    public static Objects objects{ get { return Get<Objects>("objects"); }}

}
