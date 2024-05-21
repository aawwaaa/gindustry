using Godot;
using System;

public partial class Vars: Node
{
    public static SceneTree tree;

    public static Objects objects;

    public override void _Ready()
    {
        tree = GetTree();

        objects = Attach(new Objects());
    }

    public T Attach<T>(T obj) where T: Node
    {
        obj.Name = obj.GetType().Name;
        AddChild(obj);
        return obj;
    }

    public Objects GetObjects()
    {
        return objects;
    }
}
