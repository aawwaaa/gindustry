using Godot;
using System;

public partial class Vars: Node
{
    public static readonly StringName SINGLETON_NAME = "Vars";

    public static SceneTree tree;

    public static ObjectsManager objects;

    public override void _Ready()
    {
        tree = GetTree();

        objects = Attach(new ObjectsManager());
    }

    public T Attach<T>(T obj) where T: Node
    {
        obj.Name = obj.GetType().Name;
        AddChild(obj);
        return obj;
    }

    public ObjectsManager Objects
    {
        get { return objects; }
    }
}
